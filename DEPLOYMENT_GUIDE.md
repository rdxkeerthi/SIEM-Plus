# SIEM-Plus Cloud Deployment Guide

## Quick Deployment Steps

### 1. Deploy to Kubernetes
```bash
# Linux/Mac
chmod +x scripts/deploy-kubernetes.sh
./scripts/deploy-kubernetes.sh

# Windows
.\scripts\deploy-kubernetes.ps1
```

### 2. Configure Integrations
```bash
chmod +x scripts/configure-integrations.sh
./scripts/configure-integrations.sh
```

### 3. Import Sigma Rules
```bash
chmod +x scripts/import-sigma-rules.sh
./scripts/import-sigma-rules.sh
```

### 4. Setup Monitoring
```bash
chmod +x scripts/setup-monitoring.sh
./scripts/setup-monitoring.sh
```

### 5. Scale Horizontally
```bash
chmod +x scripts/scale-deployment.sh
./scripts/scale-deployment.sh
```

## Access Points

- **UI**: http://[LoadBalancer-IP]
- **API**: http://[LoadBalancer-IP]/api/v1
- **Grafana**: kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring

## Default Credentials

- Email: admin@siem-plus.io
- Password: admin123

**⚠️ Change immediately in production!**
