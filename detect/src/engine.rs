use anyhow::Result;
use rdkafka::consumer::{Consumer, StreamConsumer};
use rdkafka::config::ClientConfig;
use rdkafka::message::Message;
use serde_json::Value;
use tracing::{info, warn, debug};

use crate::sigma::{SigmaRule, evaluate_rule};
use crate::state::StateStore;
use crate::metrics::Metrics;

pub async fn run(
    kafka_brokers: String,
    rules: Vec<SigmaRule>,
    state_store: StateStore,
    metrics: Metrics,
) -> Result<()> {
    info!("Starting detection engine");

    let consumer: StreamConsumer = ClientConfig::new()
        .set("group.id", "siem-detect-engine")
        .set("bootstrap.servers", &kafka_brokers)
        .set("enable.auto.commit", "true")
        .set("auto.offset.reset", "earliest")
        .create()?;

    consumer.subscribe(&["events"])?;
    info!("Subscribed to Kafka topic: events");

    loop {
        match consumer.recv().await {
            Ok(message) => {
                metrics.events_processed.inc();

                if let Some(payload) = message.payload() {
                    match serde_json::from_slice::<Value>(payload) {
                        Ok(event) => {
                            debug!("Processing event: {:?}", event);
                            process_event(event, &rules, &state_store, &metrics).await;
                        }
                        Err(e) => {
                            warn!("Failed to parse event: {}", e);
                            metrics.parse_errors.inc();
                        }
                    }
                }
            }
            Err(e) => {
                warn!("Kafka error: {}", e);
                tokio::time::sleep(tokio::time::Duration::from_secs(1)).await;
            }
        }
    }
}

async fn process_event(
    event: Value,
    rules: &[SigmaRule],
    state_store: &StateStore,
    metrics: &Metrics,
) {
    for rule in rules {
        if !rule.enabled {
            continue;
        }

        match evaluate_rule(rule, &event, state_store).await {
            Ok(true) => {
                info!("Rule matched: {} for event", rule.name);
                metrics.alerts_generated.inc();
                
                // Generate alert
                let alert = serde_json::json!({
                    "rule_id": rule.id,
                    "rule_name": rule.name,
                    "severity": rule.severity,
                    "event": event,
                    "timestamp": chrono::Utc::now().to_rfc3339(),
                });

                // TODO: Send alert to alert queue
                debug!("Alert generated: {:?}", alert);
            }
            Ok(false) => {
                // Rule didn't match
            }
            Err(e) => {
                warn!("Error evaluating rule {}: {}", rule.name, e);
                metrics.rule_errors.inc();
            }
        }
    }
}
