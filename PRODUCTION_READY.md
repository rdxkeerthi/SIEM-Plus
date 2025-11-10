# 🎉 SIEM-Plus - Production Ready Deployment

## ✅ Complete Feature Set Delivered

### 🚀 One-Command Deployment

```bash
# Complete production deployment
chmod +x scripts/complete-deployment.sh
./scripts/complete-deployment.sh
```

This single command will:
1. ✅ Deploy to Kubernetes cluster
2. ✅ Configure Slack, JIRA, and other integrations
3. ✅ Import 100+ Sigma detection rules
4. ✅ Setup Grafana monitoring dashboards
5. ✅ Scale horizontally (10 detection engines, 5 API servers)

## 📦 What's Included

### Deployment Automation
- **Kubernetes Deployment** (`scripts/deploy-kubernetes.sh`)
  - Automated namespace creation
  - Secret management
  - Helm chart installation
  - Health checks
  - Service endpoint discovery

- **Windows Support** (`scripts/deploy-kubernetes.ps1`)
  - Full PowerShell deployment script
  - Same features as Linux/Mac version

### Integration Configuration
- **Slack Integration** - Real-time alert notifications
- **JIRA Integration** - Automatic ticket creation
- **Email Alerts** - SMTP configuration
- **PagerDuty** - Incident management
- **Microsoft Teams** - Team notifications
- **ServiceNow** - Enterprise ticketing
- **Webhooks** - Custom integrations
- **Syslog** - Legacy system support

Configuration file: `config/integrations.yaml`

### Detection Rules
- **Sigma Rule Importer** (`scripts/import-sigma-rules.sh`)
  - Clones official Sigma repository
  - Imports rules by category:
    - Windows process creation
    - PowerShell execution
    - Linux threats
    - Network attacks
    - Web attacks
  - Converts to SIEM-Plus format
  - Uploads to Kubernetes ConfigMap

### Monitoring & Observability
- **Grafana Dashboards** (`infra/grafana/dashboards/`)
  - SIEM Overview dashboard
  - Events per second
  - Alert metrics
  - Detection latency
  - API performance
  - Kafka consumer lag
  - Resource usage

- **Prometheus Integration**
  - ServiceMonitor configuration
  - Custom metrics collection
  - Alert rules

### Horizontal Scaling
- **Auto-Scaling** (HPA)
  - Detection Engine: 10-50 replicas
  - Manager API: 5-20 replicas
  - CPU-based scaling (70-75% threshold)

- **Manual Scaling** (`scripts/scale-deployment.sh`)
  - Quick scale commands
  - Pod status monitoring

### Kubernetes Resources
Complete Helm chart with:
- **Deployments** - Manager, Detection Engine, UI
- **Services** - ClusterIP and LoadBalancer
- **HPA** - Horizontal Pod Autoscalers
- **Ingress** - NGINX with TLS/SSL
- **ConfigMaps** - Configuration management
- **Secrets** - Secure credential storage

## 🎯 Production Configuration

### High Availability Setup
```yaml
# config/values-prod.yaml

manager:
  replicaCount: 5
  autoscaling:
    minReplicas: 5
    maxReplicas: 20

detect:
  replicaCount: 10
  autoscaling:
    minReplicas: 10
    maxReplicas: 50

postgresql:
  primary:
    persistence:
      size: 100Gi
    resources:
      memory: 8Gi

opensearch:
  replicas: 5
  persistence:
    size: 1Ti
```

### Resource Allocation
- **Detection Engine**: 2-4 CPU, 1-2GB RAM per pod
- **Manager API**: 1-2 CPU, 512MB-1GB RAM per pod
- **PostgreSQL**: 4 CPU, 8GB RAM
- **OpenSearch**: 8 CPU, 16GB RAM per node
- **Kafka**: 4 CPU, 8GB RAM per broker

### Performance Targets
- **Throughput**: 1M+ events/sec (cluster)
- **Latency**: <100ms detection p99
- **API Response**: <50ms p95
- **Availability**: 99.9% uptime
- **Scalability**: Linear horizontal scaling

## 🔧 Quick Start Commands

### Deploy Everything
```bash
./scripts/complete-deployment.sh
```

### Individual Steps
```bash
# 1. Deploy to Kubernetes
./scripts/deploy-kubernetes.sh

# 2. Configure integrations
./scripts/configure-integrations.sh

# 3. Import Sigma rules
./scripts/import-sigma-rules.sh

# 4. Setup monitoring
./scripts/setup-monitoring.sh

# 5. Scale deployment
./scripts/scale-deployment.sh
```

### Access Services
```bash
# Get UI URL
kubectl get svc siem-plus-ui -n siem-plus

# Port forward Grafana
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring

# View logs
kubectl logs -f deployment/siem-plus-manager -n siem-plus

# Check pod status
kubectl get pods -n siem-plus
```

## 📊 Monitoring Access

### Grafana Dashboards
```bash
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring
# Access: http://localhost:3000
# Login: admin / admin
```

**Available Dashboards:**
- SIEM Overview
- Detection Engine Performance
- API Metrics
- Infrastructure Health
- Kafka Metrics

### Prometheus Metrics
```bash
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring
# Access: http://localhost:9090
```

**Key Metrics:**
- `events_processed_total` - Total events processed
- `alerts_generated_total` - Total alerts generated
- `detection_latency_seconds` - Detection latency histogram
- `http_requests_total` - API request count
- `kafka_consumer_lag` - Consumer lag

## 🔐 Security Configuration

### Secrets Management
```bash
# Database credentials
kubectl create secret generic siem-plus-secrets \
  --from-literal=database-url="postgres://..." \
  -n siem-plus

# JWT secret
kubectl create secret generic siem-plus-jwt \
  --from-literal=jwt-secret="..." \
  -n siem-plus

# Integration secrets
kubectl create secret generic slack-config \
  --from-literal=webhook-url="..." \
  -n siem-plus
```

### TLS/SSL Configuration
```yaml
# Ingress with cert-manager
ingress:
  enabled: true
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  tls:
    - secretName: siem-plus-tls
      hosts:
        - siem.yourcompany.com
```

## 📈 Scaling Strategies

### Vertical Scaling
```bash
# Increase resources
kubectl set resources deployment siem-plus-detect \
  --limits=cpu=8000m,memory=4Gi \
  --requests=cpu=4000m,memory=2Gi \
  -n siem-plus
```

### Horizontal Scaling
```bash
# Manual scale
kubectl scale deployment siem-plus-detect --replicas=20 -n siem-plus

# Auto-scaling (already configured via HPA)
kubectl get hpa -n siem-plus
```

### Database Scaling
```bash
# Increase PostgreSQL storage
kubectl patch pvc data-siem-plus-postgresql-0 \
  -p '{"spec":{"resources":{"requests":{"storage":"200Gi"}}}}' \
  -n siem-plus
```

## 🎓 Integration Examples

### Slack Notification
```yaml
# config/integrations.yaml
slack:
  enabled: true
  webhook_url: "https://hooks.slack.com/services/..."
  channels:
    critical_alerts: "#security-critical"
    high_alerts: "#security-high"
```

### JIRA Ticket Creation
```yaml
jira:
  enabled: true
  url: "https://yourcompany.atlassian.net"
  username: "automation@company.com"
  api_token: "your-api-token"
  project: "SEC"
  auto_create:
    - severity: critical
      issue_type: "Incident"
```

### Email Alerts
```yaml
email:
  enabled: true
  smtp_host: "smtp.gmail.com"
  smtp_port: 587
  smtp_username: "alerts@company.com"
  smtp_password: "app-password"
  recipients:
    critical:
      - "security-team@company.com"
```

## 🔍 Troubleshooting

### Check Deployment Status
```bash
kubectl get pods -n siem-plus
kubectl describe pod <pod-name> -n siem-plus
kubectl logs -f <pod-name> -n siem-plus
```

### Common Issues

**Pods not starting:**
```bash
kubectl describe pod <pod-name> -n siem-plus
# Check events and resource constraints
```

**Database connection errors:**
```bash
kubectl get secret siem-plus-secrets -n siem-plus -o yaml
# Verify database URL is correct
```

**High latency:**
```bash
kubectl top pods -n siem-plus
# Check resource usage and scale if needed
```

## 📚 Documentation

- **Getting Started**: `docs/getting-started.md`
- **Architecture**: `docs/architecture.md`
- **Deployment Guide**: `docs/deployment.md`
- **API Reference**: `docs/api-reference.md`
- **Quick Deployment**: `DEPLOYMENT_GUIDE.md`

## 🌟 Production Checklist

- [x] Kubernetes cluster configured
- [x] Helm 3 installed
- [x] kubectl configured
- [x] Deployment scripts ready
- [x] Integration configs prepared
- [x] Sigma rules imported
- [x] Monitoring dashboards configured
- [x] Auto-scaling enabled
- [x] Secrets management configured
- [x] TLS/SSL certificates ready
- [x] Backup strategy defined
- [x] Disaster recovery plan documented

## 🚀 Next Steps After Deployment

1. **Change Default Credentials**
   - Login: admin@siem-plus.io / admin123
   - Change immediately!

2. **Deploy Agents**
   - Download agent binary
   - Configure with manager URL
   - Deploy to endpoints

3. **Customize Detection Rules**
   - Review imported Sigma rules
   - Enable/disable as needed
   - Create custom rules

4. **Configure Notifications**
   - Test Slack integration
   - Verify JIRA tickets
   - Setup email alerts

5. **Monitor Performance**
   - Review Grafana dashboards
   - Set up alerts
   - Optimize resources

## 📞 Support

- **GitHub**: https://github.com/rdxkeerthi/SIEM-Plus
- **Issues**: https://github.com/rdxkeerthi/SIEM-Plus/issues
- **Documentation**: https://github.com/rdxkeerthi/SIEM-Plus/tree/main/docs

---

**🎉 SIEM-Plus is Production Ready!**

Deploy with confidence using enterprise-grade security monitoring.
