use anyhow::Result;
use crossbeam_channel::Receiver;
use reqwest::Client;
use serde_json::json;
use tracing::{info, warn, error};
use std::time::Duration;

use crate::config::Config;
use crate::telemetry::TelemetryEvent;

mod batch;

pub async fn run(config: Config, event_rx: Receiver<TelemetryEvent>) -> Result<()> {
    info!("Starting event uploader");
    
    let client = Client::builder()
        .timeout(Duration::from_secs(30))
        .build()?;

    let mut batch = Vec::new();
    let batch_size = config.performance.batch_size;
    let flush_interval = Duration::from_secs(config.performance.flush_interval);
    let mut last_flush = std::time::Instant::now();

    loop {
        // Try to receive events with timeout
        match event_rx.recv_timeout(Duration::from_secs(1)) {
            Ok(event) => {
                batch.push(event);
                
                // Flush if batch is full
                if batch.len() >= batch_size {
                    flush_batch(&client, &config, &mut batch).await;
                    last_flush = std::time::Instant::now();
                }
            }
            Err(crossbeam_channel::RecvTimeoutError::Timeout) => {
                // Flush if interval elapsed
                if last_flush.elapsed() >= flush_interval && !batch.is_empty() {
                    flush_batch(&client, &config, &mut batch).await;
                    last_flush = std::time::Instant::now();
                }
            }
            Err(crossbeam_channel::RecvTimeoutError::Disconnected) => {
                // Channel closed, flush remaining events and exit
                if !batch.is_empty() {
                    flush_batch(&client, &config, &mut batch).await;
                }
                info!("Event channel closed, uploader stopping");
                break;
            }
        }
    }

    Ok(())
}

async fn flush_batch(client: &Client, config: &Config, batch: &mut Vec<TelemetryEvent>) {
    if batch.is_empty() {
        return;
    }

    info!("Flushing {} events to manager", batch.len());

    let payload = json!({
        "tenant_id": config.manager.tenant_id,
        "events": batch,
    });

    match client
        .post(format!("{}/api/v1/events", config.manager.url))
        .header("Authorization", format!("Bearer {}", config.manager.agent_key))
        .json(&payload)
        .send()
        .await
    {
        Ok(response) => {
            if response.status().is_success() {
                info!("Successfully uploaded {} events", batch.len());
                batch.clear();
            } else {
                error!("Failed to upload events: {}", response.status());
                // TODO: Implement retry logic with exponential backoff
            }
        }
        Err(e) => {
            error!("Network error uploading events: {}", e);
            // TODO: Implement local buffering for offline scenarios
        }
    }
}
