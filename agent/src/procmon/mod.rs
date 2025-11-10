use anyhow::Result;
use crossbeam_channel::Sender;
use serde::{Deserialize, Serialize};
use tracing::{info, debug};

use crate::config::Config;

mod tracker;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProcessEvent {
    pub id: String,
    pub timestamp: chrono::DateTime<chrono::Utc>,
    pub event_type: String,
    pub pid: u32,
    pub ppid: Option<u32>,
    pub name: String,
    pub command_line: Option<String>,
    pub user: Option<String>,
    pub action: String, // started, terminated, modified
}

pub async fn run(config: Config, event_tx: Sender<crate::telemetry::TelemetryEvent>) -> Result<()> {
    info!("Starting Process Monitor");
    
    // Platform-specific process monitoring
    #[cfg(target_os = "windows")]
    {
        tracker::windows::monitor_processes(config, event_tx).await
    }
    
    #[cfg(target_os = "linux")]
    {
        tracker::linux::monitor_processes(config, event_tx).await
    }
    
    #[cfg(target_os = "macos")]
    {
        tracker::macos::monitor_processes(config, event_tx).await
    }
}
