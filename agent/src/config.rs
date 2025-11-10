use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::path::Path;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub manager: ManagerConfig,
    pub tls: TlsConfig,
    pub fim: FimConfig,
    pub procmon: ProcmonConfig,
    pub netmon: NetmonConfig,
    pub telemetry: TelemetryConfig,
    pub logging: LoggingConfig,
    pub performance: PerformanceConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ManagerConfig {
    pub url: String,
    pub tenant_id: String,
    pub agent_key: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TlsConfig {
    pub verify_server: bool,
    pub ca_cert: Option<String>,
    pub client_cert: Option<String>,
    pub client_key: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FimConfig {
    pub enabled: bool,
    pub paths: Vec<FimPath>,
    pub scan_interval: u64,
    pub hash_algorithm: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FimPath {
    pub path: String,
    pub recursive: bool,
    #[serde(default)]
    pub exclude: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProcmonConfig {
    pub enabled: bool,
    pub track_network: bool,
    pub track_file_access: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NetmonConfig {
    pub enabled: bool,
    pub track_connections: bool,
    pub track_dns: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TelemetryConfig {
    pub enabled: bool,
    pub interval: u64,
    pub metrics: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LoggingConfig {
    pub level: String,
    pub format: String,
    pub output: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PerformanceConfig {
    pub max_memory_mb: usize,
    pub max_cpu_percent: f32,
    pub batch_size: usize,
    pub flush_interval: u64,
}

impl Config {
    pub fn load<P: AsRef<Path>>(path: P) -> Result<Self> {
        let content = std::fs::read_to_string(path)?;
        let mut config: Config = serde_yaml::from_str(&content)?;
        
        // Expand environment variables
        config.expand_env_vars();
        
        Ok(config)
    }

    fn expand_env_vars(&mut self) {
        self.manager.agent_key = expand_env(&self.manager.agent_key);
        self.manager.url = expand_env(&self.manager.url);
        self.manager.tenant_id = expand_env(&self.manager.tenant_id);
    }
}

fn expand_env(value: &str) -> String {
    if value.starts_with("${") && value.ends_with('}') {
        let var_name = &value[2..value.len() - 1];
        std::env::var(var_name).unwrap_or_else(|_| value.to_string())
    } else {
        value.to_string()
    }
}

impl Default for Config {
    fn default() -> Self {
        Self {
            manager: ManagerConfig {
                url: "https://manager.siem-plus.io".to_string(),
                tenant_id: "default".to_string(),
                agent_key: "".to_string(),
            },
            tls: TlsConfig {
                verify_server: true,
                ca_cert: None,
                client_cert: None,
                client_key: None,
            },
            fim: FimConfig {
                enabled: true,
                paths: vec![],
                scan_interval: 300,
                hash_algorithm: "blake3".to_string(),
            },
            procmon: ProcmonConfig {
                enabled: true,
                track_network: true,
                track_file_access: true,
            },
            netmon: NetmonConfig {
                enabled: true,
                track_connections: true,
                track_dns: true,
            },
            telemetry: TelemetryConfig {
                enabled: true,
                interval: 60,
                metrics: vec!["cpu".to_string(), "memory".to_string(), "disk".to_string()],
            },
            logging: LoggingConfig {
                level: "info".to_string(),
                format: "json".to_string(),
                output: "/var/log/siem-agent/agent.log".to_string(),
            },
            performance: PerformanceConfig {
                max_memory_mb: 100,
                max_cpu_percent: 5.0,
                batch_size: 100,
                flush_interval: 10,
            },
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_expand_env_vars() {
        std::env::set_var("TEST_VAR", "test_value");
        assert_eq!(expand_env("${TEST_VAR}"), "test_value");
        assert_eq!(expand_env("plain_value"), "plain_value");
    }

    #[test]
    fn test_default_config() {
        let config = Config::default();
        assert!(config.fim.enabled);
        assert!(config.telemetry.enabled);
        assert_eq!(config.performance.batch_size, 100);
    }
}
