use std::sync::Arc;
use std::time::Duration;

use anyhow::{Context, Result};
use rdkafka::config::ClientConfig;
use rdkafka::producer::{FutureProducer, FutureRecord};
use serde_json::Value;

#[derive(Clone)]
pub struct AlertProducer {
    producer: Arc<FutureProducer>,
    topic: String,
}

impl AlertProducer {
    pub fn new(brokers: &str, topic: String) -> Result<Self> {
        let producer: FutureProducer = ClientConfig::new()
            .set("bootstrap.servers", brokers)
            .set("message.timeout.ms", "5000")
            .create()
            .context("failed to create Kafka alert producer")?;

        Ok(Self {
            producer: Arc::new(producer),
            topic,
        })
    }

    pub async fn send(&self, alert: Value) -> Result<()> {
        let key = alert
            .get("tenant_id")
            .and_then(|v| v.as_str())
            .unwrap_or("siem-plus");

        let payload = serde_json::to_vec(&alert)?;
        self.producer
            .send(
                FutureRecord::to(&self.topic)
                    .payload(&payload)
                    .key(key),
                Duration::from_secs(5),
            )
            .await
            .map_err(|(err, _)| err)
            .context("failed to publish alert to Kafka")?;

        Ok(())
    }
}
