use anyhow::Result;
use redis::AsyncCommands;
use std::sync::Arc;

#[derive(Clone)]
pub struct StateStore {
    client: Arc<redis::Client>,
}

impl StateStore {
    pub async fn new(redis_url: &str) -> Result<Self> {
        let client = redis::Client::open(redis_url)?;
        Ok(Self {
            client: Arc::new(client),
        })
    }

    pub async fn get(&self, key: &str) -> Result<Option<String>> {
        let mut conn = self.client.get_async_connection().await?;
        let value: Option<String> = conn.get(key).await?;
        Ok(value)
    }

    pub async fn set(&self, key: &str, value: &str, ttl_seconds: usize) -> Result<()> {
        let mut conn = self.client.get_async_connection().await?;
        conn.set_ex(key, value, ttl_seconds).await?;
        Ok(())
    }

    pub async fn increment(&self, key: &str) -> Result<i64> {
        let mut conn = self.client.get_async_connection().await?;
        let count: i64 = conn.incr(key, 1).await?;
        Ok(count)
    }

    pub async fn get_count(&self, key: &str) -> Result<i64> {
        let mut conn = self.client.get_async_connection().await?;
        let count: i64 = conn.get(key).await.unwrap_or(0);
        Ok(count)
    }
}
