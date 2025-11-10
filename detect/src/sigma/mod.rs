use anyhow::Result;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::fs;
use std::path::Path;
use tracing::{info, warn};

use crate::state::StateStore;

mod parser;
mod compiler;
mod evaluator;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SigmaRule {
    pub id: String,
    pub name: String,
    pub description: Option<String>,
    pub severity: String,
    pub enabled: bool,
    pub detection: Detection,
    pub tags: Vec<String>,
    pub mitre_attack: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Detection {
    pub selection: Vec<Condition>,
    pub condition: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Condition {
    pub field: String,
    pub operator: String,
    pub value: Value,
}

pub fn load_rules<P: AsRef<Path>>(path: P) -> Result<Vec<SigmaRule>> {
    let mut rules = Vec::new();
    let path = path.as_ref();

    if !path.exists() {
        warn!("Rules directory does not exist: {:?}", path);
        return Ok(rules);
    }

    for entry in fs::read_dir(path)? {
        let entry = entry?;
        let path = entry.path();

        if path.extension().and_then(|s| s.to_str()) == Some("yml") 
            || path.extension().and_then(|s| s.to_str()) == Some("yaml") {
            match load_sigma_rule(&path) {
                Ok(rule) => {
                    info!("Loaded rule: {}", rule.name);
                    rules.push(rule);
                }
                Err(e) => {
                    warn!("Failed to load rule from {:?}: {}", path, e);
                }
            }
        }
    }

    Ok(rules)
}

fn load_sigma_rule<P: AsRef<Path>>(path: P) -> Result<SigmaRule> {
    let content = fs::read_to_string(path)?;
    let rule: SigmaRule = serde_yaml::from_str(&content)?;
    Ok(rule)
}

pub async fn evaluate_rule(
    rule: &SigmaRule,
    event: &Value,
    _state_store: &StateStore,
) -> Result<bool> {
    // Simplified rule evaluation
    // In production, this would use the compiled rule logic
    
    for condition in &rule.detection.selection {
        if !evaluate_condition(condition, event) {
            return Ok(false);
        }
    }

    Ok(true)
}

fn evaluate_condition(condition: &Condition, event: &Value) -> bool {
    let field_value = event.get(&condition.field);

    match condition.operator.as_str() {
        "equals" => {
            field_value == Some(&condition.value)
        }
        "contains" => {
            if let (Some(Value::String(field_str)), Value::String(search_str)) = 
                (field_value, &condition.value) {
                field_str.contains(search_str)
            } else {
                false
            }
        }
        "regex" => {
            if let (Some(Value::String(field_str)), Value::String(pattern)) = 
                (field_value, &condition.value) {
                if let Ok(re) = regex::Regex::new(pattern) {
                    re.is_match(field_str)
                } else {
                    false
                }
            } else {
                false
            }
        }
        _ => false,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_evaluate_condition_equals() {
        let condition = Condition {
            field: "event_type".to_string(),
            operator: "equals".to_string(),
            value: Value::String("process_start".to_string()),
        };

        let event = serde_json::json!({
            "event_type": "process_start"
        });

        assert!(evaluate_condition(&condition, &event));
    }

    #[test]
    fn test_evaluate_condition_contains() {
        let condition = Condition {
            field: "command_line".to_string(),
            operator: "contains".to_string(),
            value: Value::String("powershell".to_string()),
        };

        let event = serde_json::json!({
            "command_line": "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe"
        });

        assert!(evaluate_condition(&condition, &event));
    }
}
