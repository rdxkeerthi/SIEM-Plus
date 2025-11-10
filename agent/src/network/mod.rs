use anyhow::Result;
use crossbeam_channel::Sender;
use serde::{Deserialize, Serialize};
use tracing::info;

use crate::config::Config;

mod connections;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NetworkEvent {
    pub id: String,
    pub timestamp: chrono::DateTime<chrono::Utc>,
    pub event_type: String,
    pub protocol: String,
    pub src_ip: String,
    pub src_port: u16,
    pub dst_ip: String,
    pub dst_port: u16,
    pub pid: Option<u32>,
    pub process_name: Option<String>,
    pub action: String, // established, closed, listening
}

pub async fn run(config: Config, event_tx: Sender<crate::telemetry::TelemetryEvent>) -> Result<()> {
    info!("Starting Network Monitor");
    
    // Platform-specific network monitoring
    connections::monitor_connections(config, event_tx).await
}
