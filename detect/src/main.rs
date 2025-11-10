use anyhow::Result;
use clap::Parser;
use tracing::{info, error};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

mod engine;
mod sigma;
mod state;
mod metrics;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    #[arg(short, long, default_value = "0.0.0.0:8081")]
    listen: String,

    #[arg(long, default_value = "localhost:9092")]
    kafka_brokers: String,

    #[arg(long, default_value = "redis://localhost:6379")]
    redis_url: String,

    #[arg(long, default_value = "./rules")]
    rules_path: String,
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "info".into()),
        )
        .with(tracing_subscriber::fmt::layer().json())
        .init();

    let args = Args::parse();
    info!("SIEM-Plus Detection Engine starting...");
    info!("Version: {}", env!("CARGO_PKG_VERSION"));

    // Initialize metrics
    let metrics = metrics::Metrics::new();

    // Initialize state store
    let state_store = state::StateStore::new(&args.redis_url).await?;
    info!("Connected to state store");

    // Load Sigma rules
    let rules = sigma::load_rules(&args.rules_path)?;
    info!("Loaded {} detection rules", rules.len());

    // Start detection engine
    let engine_handle = tokio::spawn({
        let kafka_brokers = args.kafka_brokers.clone();
        let metrics = metrics.clone();
        async move {
            if let Err(e) = engine::run(kafka_brokers, rules, state_store, metrics).await {
                error!("Detection engine error: {}", e);
            }
        }
    });

    // Start metrics server
    let metrics_handle = tokio::spawn({
        let listen = args.listen.clone();
        let metrics = metrics.clone();
        async move {
            if let Err(e) = metrics::serve(listen, metrics).await {
                error!("Metrics server error: {}", e);
            }
        }
    });

    info!("Detection engine running on {}", args.listen);

    tokio::select! {
        _ = engine_handle => info!("Engine stopped"),
        _ = metrics_handle => info!("Metrics server stopped"),
        _ = tokio::signal::ctrl_c() => info!("Shutdown signal received"),
    }

    Ok(())
}
