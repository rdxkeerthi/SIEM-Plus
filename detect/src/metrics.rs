use anyhow::Result;
use axum::{routing::get, Router};
use prometheus::{Encoder, TextEncoder, Counter, Registry};
use std::sync::Arc;

#[derive(Clone)]
pub struct Metrics {
    pub events_processed: Counter,
    pub alerts_generated: Counter,
    pub rule_errors: Counter,
    pub parse_errors: Counter,
    registry: Arc<Registry>,
}

impl Metrics {
    pub fn new() -> Self {
        let registry = Registry::new();

        let events_processed = Counter::new("events_processed_total", "Total events processed").unwrap();
        let alerts_generated = Counter::new("alerts_generated_total", "Total alerts generated").unwrap();
        let rule_errors = Counter::new("rule_errors_total", "Total rule evaluation errors").unwrap();
        let parse_errors = Counter::new("parse_errors_total", "Total parse errors").unwrap();

        registry.register(Box::new(events_processed.clone())).unwrap();
        registry.register(Box::new(alerts_generated.clone())).unwrap();
        registry.register(Box::new(rule_errors.clone())).unwrap();
        registry.register(Box::new(parse_errors.clone())).unwrap();

        Self {
            events_processed,
            alerts_generated,
            rule_errors,
            parse_errors,
            registry: Arc::new(registry),
        }
    }
}

pub async fn serve(listen: String, metrics: Metrics) -> Result<()> {
    let app = Router::new()
        .route("/metrics", get(move || async move {
            let encoder = TextEncoder::new();
            let metric_families = metrics.registry.gather();
            let mut buffer = vec![];
            encoder.encode(&metric_families, &mut buffer).unwrap();
            String::from_utf8(buffer).unwrap()
        }))
        .route("/health", get(|| async { "OK" }));

    let listener = tokio::net::TcpListener::bind(&listen).await?;
    axum::serve(listener, app).await?;
    Ok(())
}
