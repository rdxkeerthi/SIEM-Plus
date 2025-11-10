# Getting Started with SIEM-Plus

This guide will help you get SIEM-Plus up and running in your environment.

## Prerequisites

- Docker & Docker Compose (for local development)
- Kubernetes cluster (for production deployment)
- Rust 1.70+ (for agent development)
- Go 1.21+ (for manager/ingest development)
- Node.js 18+ (for UI development)
- Python 3.11+ (for SOAR development)

## Quick Start (Local Development)

### 1. Clone the Repository

```bash
git clone https://github.com/rdxkeerthi/SIEM-Plus.git
cd SIEM-Plus
```

### 2. Start Infrastructure Services

```bash
# Start Kafka, OpenSearch, Redis, PostgreSQL, etc.
make dev-up

# Wait for services to be ready (about 30 seconds)
```

This will start:
- **Kafka** on `localhost:9092` - Event streaming
- **OpenSearch** on `localhost:9200` - Event storage
- **PostgreSQL** on `localhost:5432` - Metadata storage
- **Redis** on `localhost:6379` - State management
- **Grafana** on `localhost:3000` - Monitoring dashboards
- **Prometheus** on `localhost:9090` - Metrics collection

### 3. Initialize Database

The database will be automatically initialized with the schema and default data when PostgreSQL starts.

Default credentials:
- **Email**: admin@siem-plus.io
- **Password**: admin123

### 4. Start Backend Services

#### Start Manager API

```bash
cd manager
go run ./cmd/server
```

The API will be available at `http://localhost:8080`

#### Start Detection Engine

```bash
cd detect
cargo run --release
```

The detection engine will start processing events from Kafka.

### 5. Start UI

```bash
cd ui
npm install
npm run dev
```

The UI will be available at `http://localhost:3000`

### 6. Deploy Your First Agent

#### Linux/macOS

```bash
cd agent
cargo build --release

# Create config file
cat > /tmp/agent-config.yaml <<EOF
manager:
  url: "http://localhost:8080"
  tenant_id: "default"
  agent_key: "your-agent-key"

fim:
  enabled: true
  paths:
    - path: "/tmp/test"
      recursive: true
  scan_interval: 60

telemetry:
  enabled: true
  interval: 30
  metrics:
    - cpu
    - memory
    - disk
EOF

# Run agent
./target/release/siem-agent --config /tmp/agent-config.yaml
```

#### Windows

```powershell
cd agent
cargo build --release

# Create config file
$config = @"
manager:
  url: "http://localhost:8080"
  tenant_id: "default"
  agent_key: "your-agent-key"

fim:
  enabled: true
  paths:
    - path: "C:\\Temp"
      recursive: true
  scan_interval: 60

telemetry:
  enabled: true
  interval: 30
  metrics:
    - cpu
    - memory
    - disk
"@

$config | Out-File -FilePath agent-config.yaml

# Run agent
.\target\release\siem-agent.exe --config agent-config.yaml
```

## Production Deployment

### Kubernetes Deployment

```bash
# Install using Helm
cd infra/helm-charts

# Update values for your environment
cp values.yaml values-prod.yaml
# Edit values-prod.yaml with your settings

# Install
helm install siem-plus ./siem-plus -f values-prod.yaml
```

### Configuration

Key configuration areas:

1. **Database Connection**
   - Update PostgreSQL connection string
   - Configure connection pooling

2. **Message Broker**
   - Configure Kafka cluster endpoints
   - Set topic partitions and replication

3. **Storage**
   - Configure OpenSearch cluster
   - Set index lifecycle policies
   - Configure S3 for snapshots

4. **Authentication**
   - Configure JWT secret
   - Set up SSO/OIDC integration
   - Enable MFA

5. **TLS/mTLS**
   - Generate certificates
   - Configure certificate authorities
   - Enable mTLS for internal communication

## Testing the System

### 1. Login to UI

Navigate to `http://localhost:3000` and login with:
- Email: admin@siem-plus.io
- Password: admin123

### 2. Verify Agent Connection

Go to **Agents** page and verify your agent appears with status "Active"

### 3. Create a Test Alert

Create a test file to trigger FIM alert:

```bash
# On the system running the agent
echo "test" > /tmp/test/suspicious.txt
```

Check the **Alerts** page for the file change detection.

### 4. Create a Detection Rule

Go to **Rules** page and create a Sigma rule:

```yaml
id: test-rule-001
name: Test PowerShell Detection
description: Detects PowerShell execution
severity: high
enabled: true
detection:
  selection:
    - field: process_name
      operator: contains
      value: powershell
  condition: all of selection
tags:
  - test
  - powershell
mitre_attack:
  - T1059.001
```

### 5. Test SOAR Playbook

Create a simple playbook to auto-assign critical alerts:

```yaml
name: Auto-assign Critical Alerts
trigger_type: alert_created
trigger_conditions:
  severity: critical
actions:
  - type: assign_alert
    params:
      user: admin@siem-plus.io
  - type: send_notification
    params:
      channel: slack
      message: "Critical alert detected"
```

## Monitoring

### Grafana Dashboards

Access Grafana at `http://localhost:3000` (admin/admin)

Pre-configured dashboards:
- **SIEM Overview** - System health and metrics
- **Detection Engine** - Rule performance and alerts
- **Agent Health** - Agent status and telemetry
- **Infrastructure** - Kafka, OpenSearch, Redis metrics

### Prometheus Metrics

Access Prometheus at `http://localhost:9090`

Key metrics:
- `events_processed_total` - Total events processed
- `alerts_generated_total` - Total alerts generated
- `agent_status` - Agent health status
- `rule_evaluation_duration` - Rule evaluation performance

## Troubleshooting

### Agent Not Connecting

```bash
# Test connectivity
curl http://localhost:8080/health

# Check agent logs
./siem-agent --log-level debug
```

### No Alerts Generated

1. Verify detection engine is running
2. Check Kafka topics have events
3. Verify rules are enabled
4. Check detection engine logs

### UI Not Loading

```bash
# Check API connectivity
curl http://localhost:8080/api/v1/dashboard/stats

# Check browser console for errors
# Verify CORS settings in manager config
```

### Database Connection Issues

```bash
# Test PostgreSQL connection
psql -h localhost -U siem_admin -d siem_plus

# Check connection string in manager config
# Verify PostgreSQL is running
docker ps | grep postgres
```

## Next Steps

1. **Configure Integrations**
   - Set up Slack notifications
   - Configure JIRA for case management
   - Integrate with SIEM/SOAR tools

2. **Import Detection Rules**
   - Browse Sigma rule marketplace
   - Import community rule packs
   - Customize rules for your environment

3. **Set Up Playbooks**
   - Create automated response workflows
   - Configure enrichment playbooks
   - Set up escalation procedures

4. **Scale the System**
   - Add more detection engine instances
   - Scale Kafka partitions
   - Configure OpenSearch cluster

5. **Security Hardening**
   - Enable mTLS
   - Configure firewall rules
   - Set up audit logging
   - Implement secrets management

## Support

- **Documentation**: https://docs.siem-plus.io
- **GitHub Issues**: https://github.com/rdxkeerthi/SIEM-Plus/issues
- **Community**: https://discord.gg/siem-plus
- **Email**: support@siem-plus.io
