# SIEM-Plus Detection Engine

Stream-based detection engine with native Sigma rule support.

## Features

- **Real-time Detection**: Stream processing with sub-second latency
- **Sigma Rules**: Native support for Sigma detection rules
- **Stateful Correlation**: Time-window based event correlation
- **High Performance**: Processes 100K+ events/second per instance
- **Horizontal Scaling**: Kafka consumer groups for parallel processing
- **Rule Testing**: Built-in rule testing framework

## Architecture

```
Kafka Events → Detection Engine → Redis State Store
                      ↓
                  Alerts Queue
```

## Running

```bash
# Start with default settings
cargo run --release

# Custom configuration
cargo run --release -- \
  --kafka-brokers localhost:9092 \
  --redis-url redis://localhost:6379 \
  --rules-path ./rules \
  --listen 0.0.0.0:8081
```

## Sigma Rule Format

```yaml
id: unique-rule-id
name: Suspicious PowerShell Execution
description: Detects suspicious PowerShell command execution
severity: high
enabled: true
detection:
  selection:
    - field: event_type
      operator: equals
      value: process_start
    - field: process_name
      operator: contains
      value: powershell.exe
    - field: command_line
      operator: regex
      value: .*-enc.*
  condition: all of selection
tags:
  - attack.execution
  - attack.t1059.001
mitre_attack:
  - T1059.001
```

## Performance Tuning

- Increase Kafka consumer threads for higher throughput
- Use Redis cluster for distributed state
- Optimize rule complexity
- Enable rule caching

## Monitoring

Metrics available at `/metrics`:
- `events_processed_total`
- `alerts_generated_total`
- `rule_errors_total`
- `parse_errors_total`
