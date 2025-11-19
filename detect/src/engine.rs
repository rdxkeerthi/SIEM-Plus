use anyhow::Result;
use rdkafka::config::ClientConfig;
use rdkafka::consumer::{Consumer, StreamConsumer};
use rdkafka::message::Message;
use serde_json::{json, Value};
use tracing::{debug, info, warn};
use uuid::Uuid;

use crate::alerts::AlertProducer;
use crate::metrics::Metrics;
use crate::sigma::{evaluate_rule, SigmaRule};
use crate::state::StateStore;

pub async fn run(
    kafka_brokers: String,
    rules: Vec<SigmaRule>,
    state_store: StateStore,
    metrics: Metrics,
    alert_producer: AlertProducer,
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
                            process_event(event, &rules, &state_store, &metrics, &alert_producer).await;
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
    alert_producer: &AlertProducer,
) {
    for rule in rules {
        if !rule.enabled {
            continue;
        }

        match evaluate_rule(rule, &event, state_store).await {
            Ok(true) => {
                info!("Rule matched: {} for event", rule.name);
                metrics.alerts_generated.inc();
                
                let tenant_id = event
                    .get("tenant_id")
                    .and_then(|v| v.as_str())
                    .unwrap_or("default");

                let alert = json!({
                    "id": Uuid::new_v4().to_string(),
                    "tenant_id": tenant_id,
                    "rule_id": rule.id,
                    "rule_name": rule.name,
                    "severity": rule.severity,
                    "event": event,
                    "timestamp": chrono::Utc::now().to_rfc3339(),
                });

                if let Err(e) = alert_producer.send(alert.clone()).await {
                    warn!("Failed to publish alert: {}", e);
                } else {
                    debug!("Alert generated: {:?}", alert);
                }
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
