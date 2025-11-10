use anyhow::Result;
use clap::Parser;
use tracing::{info, error};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

mod config;
mod telemetry;
mod fim;
mod procmon;
mod network;
mod uploader;
mod op;
mod crypto;
mod platform;

use config::Config;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Path to configuration file
    #[arg(short, long, default_value = "/etc/siem-agent/config.yaml")]
    config: String,

    /// Validate configuration and exit
    #[arg(long)]
    validate: bool,

    /// Test connection to manager
    #[arg(long)]
    test_connection: bool,

    /// Show agent status
    #[arg(long)]
    status: bool,

    /// Log level (trace, debug, info, warn, error)
    #[arg(long)]
    log_level: Option<String>,
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();

    // Initialize logging
    let log_level = args.log_level.as_deref().unwrap_or("info");
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| log_level.into()),
        )
        .with(tracing_subscriber::fmt::layer().json())
        .init();

    info!("SIEM-Plus Agent starting...");
    info!("Version: {}", env!("CARGO_PKG_VERSION"));

    // Load configuration
    let config = Config::load(&args.config)?;
    info!("Configuration loaded from: {}", args.config);

    // Handle special commands
    if args.validate {
        info!("Configuration is valid");
        return Ok(());
    }

    if args.test_connection {
        return test_connection(&config).await;
    }

    if args.status {
        return show_status().await;
    }

    // Start agent services
    run_agent(config).await
}

async fn run_agent(config: Config) -> Result<()> {
    info!("Starting agent services...");

    // Create channels for inter-module communication
    let (event_tx, event_rx) = crossbeam_channel::unbounded();

    // Start uploader (event consumer)
    let uploader_handle = tokio::spawn({
        let config = config.clone();
        async move {
            if let Err(e) = uploader::run(config, event_rx).await {
                error!("Uploader error: {}", e);
            }
        }
    });

    // Start telemetry collector
    let telemetry_handle = if config.telemetry.enabled {
        Some(tokio::spawn({
            let config = config.clone();
            let tx = event_tx.clone();
            async move {
                if let Err(e) = telemetry::run(config, tx).await {
                    error!("Telemetry error: {}", e);
                }
            }
        }))
    } else {
        None
    };

    // Start FIM (File Integrity Monitoring)
    let fim_handle = if config.fim.enabled {
        Some(tokio::spawn({
            let config = config.clone();
            let tx = event_tx.clone();
            async move {
                if let Err(e) = fim::run(config, tx).await {
                    error!("FIM error: {}", e);
                }
            }
        }))
    } else {
        None
    };

    // Start process monitor
    let procmon_handle = if config.procmon.enabled {
        Some(tokio::spawn({
            let config = config.clone();
            let tx = event_tx.clone();
            async move {
                if let Err(e) = procmon::run(config, tx).await {
                    error!("Process monitor error: {}", e);
                }
            }
        }))
    } else {
        None
    };

    // Start network monitor
    let netmon_handle = if config.netmon.enabled {
        Some(tokio::spawn({
            let config = config.clone();
            let tx = event_tx.clone();
            async move {
                if let Err(e) = network::run(config, tx).await {
                    error!("Network monitor error: {}", e);
                }
            }
        }))
    } else {
        None
    };

    // Start live operations handler
    let op_handle = tokio::spawn({
        let config = config.clone();
        async move {
            if let Err(e) = op::run(config).await {
                error!("Operations handler error: {}", e);
            }
        }
    });

    info!("All agent services started successfully");

    // Wait for shutdown signal
    tokio::signal::ctrl_c().await?;
    info!("Shutdown signal received, stopping agent...");

    // Cleanup and wait for all tasks
    drop(event_tx);
    uploader_handle.await?;
    if let Some(h) = telemetry_handle { h.await?; }
    if let Some(h) = fim_handle { h.await?; }
    if let Some(h) = procmon_handle { h.await?; }
    if let Some(h) = netmon_handle { h.await?; }
    op_handle.await?;

    info!("Agent stopped successfully");
    Ok(())
}

async fn test_connection(config: &Config) -> Result<()> {
    info!("Testing connection to manager: {}", config.manager.url);
    
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(10))
        .build()?;

    let response = client
        .get(format!("{}/health", config.manager.url))
        .send()
        .await?;

    if response.status().is_success() {
        info!("✓ Connection successful");
        Ok(())
    } else {
        error!("✗ Connection failed: {}", response.status());
        anyhow::bail!("Connection test failed")
    }
}

async fn show_status() -> Result<()> {
    use sysinfo::{System, SystemExt, ProcessExt};
    
    let mut sys = System::new_all();
    sys.refresh_all();

    println!("SIEM-Plus Agent Status");
    println!("======================");
    println!("Version: {}", env!("CARGO_PKG_VERSION"));
    
    // Find agent process
    for (pid, process) in sys.processes() {
        if process.name().contains("siem-agent") {
            println!("PID: {}", pid);
            println!("CPU: {:.2}%", process.cpu_usage());
            println!("Memory: {:.2} MB", process.memory() as f64 / 1024.0 / 1024.0);
            println!("Status: Running");
            return Ok(());
        }
    }

    println!("Status: Not running");
    Ok(())
}
