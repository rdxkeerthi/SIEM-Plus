use anyhow::Result;
use crossbeam_channel::Sender;
use notify::{Watcher, RecursiveMode, Event, EventKind};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};
use tracing::{info, warn, debug};
use uuid::Uuid;

use crate::config::Config;

mod watcher;
mod hasher;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FimEvent {
    pub id: String,
    pub timestamp: chrono::DateTime<chrono::Utc>,
    pub event_type: String,
    pub path: String,
    pub action: String,
    pub hash_before: Option<String>,
    pub hash_after: Option<String>,
    pub size: Option<u64>,
    pub permissions: Option<String>,
}

type FileHashCache = Arc<Mutex<HashMap<PathBuf, String>>>;

pub async fn run(config: Config, event_tx: Sender<crate::telemetry::TelemetryEvent>) -> Result<()> {
    info!("Starting File Integrity Monitor");
    
    let hash_cache: FileHashCache = Arc::new(Mutex::new(HashMap::new()));
    
    // Initial scan of all monitored paths
    for fim_path in &config.fim.paths {
        info!("Scanning path: {}", fim_path.path);
        initial_scan(&fim_path.path, &hash_cache, &config.fim.hash_algorithm)?;
    }

    // Set up file watcher
    let (tx, rx) = std::sync::mpsc::channel();
    let mut watcher = notify::recommended_watcher(tx)?;

    for fim_path in &config.fim.paths {
        let mode = if fim_path.recursive {
            RecursiveMode::Recursive
        } else {
            RecursiveMode::NonRecursive
        };
        
        watcher.watch(Path::new(&fim_path.path), mode)?;
        info!("Watching path: {} (recursive: {})", fim_path.path, fim_path.recursive);
    }

    // Process file system events
    loop {
        match rx.recv() {
            Ok(Ok(event)) => {
                if let Some(fim_event) = process_fs_event(event, &hash_cache, &config).await {
                    debug!("FIM event: {:?}", fim_event);
                    
                    // Convert FimEvent to TelemetryEvent for transmission
                    let telemetry_event = crate::telemetry::TelemetryEvent {
                        id: fim_event.id.clone(),
                        timestamp: fim_event.timestamp,
                        event_type: "fim".to_string(),
                        hostname: "localhost".to_string(), // TODO: Get actual hostname
                        metrics: crate::telemetry::Metrics {
                            cpu: None,
                            memory: None,
                            disk: None,
                            network: None,
                        },
                    };
                    
                    if let Err(e) = event_tx.send(telemetry_event) {
                        warn!("Failed to send FIM event: {}", e);
                    }
                }
            }
            Ok(Err(e)) => warn!("Watch error: {}", e),
            Err(e) => {
                warn!("Channel error: {}", e);
                break;
            }
        }
    }

    Ok(())
}

fn initial_scan(path: &str, cache: &FileHashCache, algorithm: &str) -> Result<()> {
    let path = Path::new(path);
    
    if path.is_file() {
        if let Ok(hash) = hasher::hash_file(path, algorithm) {
            cache.lock().unwrap().insert(path.to_path_buf(), hash);
        }
    } else if path.is_dir() {
        for entry in std::fs::read_dir(path)? {
            let entry = entry?;
            let entry_path = entry.path();
            
            if entry_path.is_file() {
                if let Ok(hash) = hasher::hash_file(&entry_path, algorithm) {
                    cache.lock().unwrap().insert(entry_path, hash);
                }
            }
        }
    }
    
    Ok(())
}

async fn process_fs_event(
    event: Event,
    cache: &FileHashCache,
    config: &Config,
) -> Option<FimEvent> {
    let path = event.paths.first()?;
    
    // Check if path should be excluded
    if should_exclude(path, config) {
        return None;
    }

    let action = match event.kind {
        EventKind::Create(_) => "created",
        EventKind::Modify(_) => "modified",
        EventKind::Remove(_) => "deleted",
        _ => return None,
    };

    let hash_before = cache.lock().unwrap().get(path).cloned();
    let hash_after = if path.exists() {
        hasher::hash_file(path, &config.fim.hash_algorithm).ok()
    } else {
        None
    };

    // Update cache
    if let Some(ref hash) = hash_after {
        cache.lock().unwrap().insert(path.to_path_buf(), hash.clone());
    } else {
        cache.lock().unwrap().remove(path);
    }

    let metadata = std::fs::metadata(path).ok();
    
    Some(FimEvent {
        id: Uuid::new_v4().to_string(),
        timestamp: chrono::Utc::now(),
        event_type: "file_change".to_string(),
        path: path.to_string_lossy().to_string(),
        action: action.to_string(),
        hash_before,
        hash_after,
        size: metadata.as_ref().map(|m| m.len()),
        permissions: metadata.as_ref().map(|m| format!("{:?}", m.permissions())),
    })
}

fn should_exclude(path: &Path, config: &Config) -> bool {
    let path_str = path.to_string_lossy();
    
    for fim_path in &config.fim.paths {
        for pattern in &fim_path.exclude {
            if path_str.contains(pattern) {
                return true;
            }
        }
    }
    
    false
}
