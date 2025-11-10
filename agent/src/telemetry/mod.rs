use anyhow::Result;
use crossbeam_channel::Sender;
use serde::{Deserialize, Serialize};
use sysinfo::{System, SystemExt, CpuExt, DiskExt, NetworkExt};
use tracing::{info, debug};
use uuid::Uuid;

use crate::config::Config;

mod cpu;
mod memory;
mod disk;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TelemetryEvent {
    pub id: String,
    pub timestamp: chrono::DateTime<chrono::Utc>,
    pub event_type: String,
    pub hostname: String,
    pub metrics: Metrics,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Metrics {
    pub cpu: Option<CpuMetrics>,
    pub memory: Option<MemoryMetrics>,
    pub disk: Option<Vec<DiskMetrics>>,
    pub network: Option<NetworkMetrics>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CpuMetrics {
    pub usage_percent: f32,
    pub cores: usize,
    pub load_avg_1: f64,
    pub load_avg_5: f64,
    pub load_avg_15: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MemoryMetrics {
    pub total_bytes: u64,
    pub used_bytes: u64,
    pub available_bytes: u64,
    pub usage_percent: f32,
    pub swap_total_bytes: u64,
    pub swap_used_bytes: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DiskMetrics {
    pub mount_point: String,
    pub total_bytes: u64,
    pub used_bytes: u64,
    pub available_bytes: u64,
    pub usage_percent: f32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NetworkMetrics {
    pub bytes_sent: u64,
    pub bytes_received: u64,
    pub packets_sent: u64,
    pub packets_received: u64,
}

pub async fn run(config: Config, event_tx: Sender<TelemetryEvent>) -> Result<()> {
    info!("Starting telemetry collector");
    
    let mut sys = System::new_all();
    let hostname = sys.host_name().unwrap_or_else(|| "unknown".to_string());
    let interval = std::time::Duration::from_secs(config.telemetry.interval);

    loop {
        sys.refresh_all();
        
        let metrics = collect_metrics(&sys, &config.telemetry.metrics);
        
        let event = TelemetryEvent {
            id: Uuid::new_v4().to_string(),
            timestamp: chrono::Utc::now(),
            event_type: "telemetry".to_string(),
            hostname: hostname.clone(),
            metrics,
        };

        debug!("Collected telemetry: CPU={:?}, Memory={:?}", 
               event.metrics.cpu, event.metrics.memory);

        if let Err(e) = event_tx.send(event) {
            tracing::error!("Failed to send telemetry event: {}", e);
        }

        tokio::time::sleep(interval).await;
    }
}

fn collect_metrics(sys: &System, enabled_metrics: &[String]) -> Metrics {
    let mut metrics = Metrics {
        cpu: None,
        memory: None,
        disk: None,
        network: None,
    };

    for metric in enabled_metrics {
        match metric.as_str() {
            "cpu" => metrics.cpu = Some(collect_cpu_metrics(sys)),
            "memory" => metrics.memory = Some(collect_memory_metrics(sys)),
            "disk" => metrics.disk = Some(collect_disk_metrics(sys)),
            "network" => metrics.network = Some(collect_network_metrics(sys)),
            _ => {}
        }
    }

    metrics
}

fn collect_cpu_metrics(sys: &System) -> CpuMetrics {
    let global_cpu = sys.global_cpu_info();
    let load_avg = sys.load_average();
    
    CpuMetrics {
        usage_percent: global_cpu.cpu_usage(),
        cores: sys.cpus().len(),
        load_avg_1: load_avg.one,
        load_avg_5: load_avg.five,
        load_avg_15: load_avg.fifteen,
    }
}

fn collect_memory_metrics(sys: &System) -> MemoryMetrics {
    let total = sys.total_memory();
    let used = sys.used_memory();
    let available = sys.available_memory();
    
    MemoryMetrics {
        total_bytes: total,
        used_bytes: used,
        available_bytes: available,
        usage_percent: (used as f32 / total as f32) * 100.0,
        swap_total_bytes: sys.total_swap(),
        swap_used_bytes: sys.used_swap(),
    }
}

fn collect_disk_metrics(sys: &System) -> Vec<DiskMetrics> {
    sys.disks()
        .iter()
        .map(|disk| {
            let total = disk.total_space();
            let available = disk.available_space();
            let used = total - available;
            
            DiskMetrics {
                mount_point: disk.mount_point().to_string_lossy().to_string(),
                total_bytes: total,
                used_bytes: used,
                available_bytes: available,
                usage_percent: if total > 0 {
                    (used as f32 / total as f32) * 100.0
                } else {
                    0.0
                },
            }
        })
        .collect()
}

fn collect_network_metrics(sys: &System) -> NetworkMetrics {
    let networks = sys.networks();
    
    let mut total_sent = 0;
    let mut total_received = 0;
    let mut total_packets_sent = 0;
    let mut total_packets_received = 0;

    for (_name, network) in networks {
        total_sent += network.total_transmitted();
        total_received += network.total_received();
        total_packets_sent += network.total_packets_transmitted();
        total_packets_received += network.total_packets_received();
    }

    NetworkMetrics {
        bytes_sent: total_sent,
        bytes_received: total_received,
        packets_sent: total_packets_sent,
        packets_received: total_packets_received,
    }
}
