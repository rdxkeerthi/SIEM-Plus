# SIEM-Plus Deployment Guide

## Deployment Options

### 1. Local Development (Docker Compose)

```bash
# Start all services
make dev-up

# Access services
# - UI: http://localhost:3000
# - Manager API: http://localhost:8080
# - OpenSearch: http://localhost:9200
# - Grafana: http://localhost:3000
```

### 2. Kubernetes (Production)

#### Prerequisites

- Kubernetes cluster (EKS, GKE, AKS, or self-hosted)
- kubectl configured
- Helm 3.x installed

#### Deploy with Helm

```bash
# Add Helm repository (if published)
helm repo add siem-plus https://charts.siem-plus.io
helm repo update

# Install with custom values
helm install siem-plus siem-plus/siem-plus \
  --namespace siem-plus \
  --create-namespace \
  -f values-prod.yaml

# Or install from local charts
cd infra/helm-charts
helm install siem-plus ./siem-plus \
  --namespace siem-plus \
  --create-namespace \
  -f values-prod.yaml
```

#### Custom Values Example

```yaml
# values-prod.yaml
manager:
  replicaCount: 5
  resources:
    limits:
      cpu: 2000m
      memory: 1Gi

detect:
  replicaCount: 10
  autoscaling:
    maxReplicas: 30

ingress:
  enabled: true
  hosts:
    - host: siem.yourcompany.com
      paths:
        - path: /
  tls:
    - secretName: siem-tls
      hosts:
        - siem.yourcompany.com

postgresql:
  auth:
    password: "your-secure-password"
  primary:
    persistence:
      size: 100Gi

opensearch:
  replicas: 5
  persistence:
    size: 1Ti
```

### 3. AWS (Terraform)

#### Deploy Infrastructure

```bash
cd infra/terraform

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file="prod.tfvars"

# Apply infrastructure
terraform apply -var-file="prod.tfvars"

# Get outputs
terraform output
```

#### prod.tfvars Example

```hcl
aws_region   = "us-east-1"
cluster_name = "siem-plus-prod"

tags = {
  Project     = "SIEM-Plus"
  Environment = "production"
  Team        = "Security"
}
```

#### Deploy Application to EKS

```bash
# Configure kubectl
aws eks update-kubeconfig --name siem-plus-prod --region us-east-1

# Deploy with Helm
helm install siem-plus ./infra/helm-charts/siem-plus \
  --namespace siem-plus \
  --create-namespace \
  --set postgresql.enabled=false \
  --set postgresql.externalHost=$(terraform output -raw database_endpoint) \
  --set redis.enabled=false \
  --set redis.externalHost=$(terraform output -raw redis_endpoint) \
  --set kafka.enabled=false \
  --set kafka.externalBrokers=$(terraform output -raw kafka_bootstrap_brokers)
```

## Post-Deployment Configuration

### 1. Database Migration

```bash
# Run database migrations
kubectl exec -it deployment/siem-plus-manager -n siem-plus -- \
  ./manager migrate up
```

### 2. Create Admin User

```bash
# Access manager pod
kubectl exec -it deployment/siem-plus-manager -n siem-plus -- sh

# Create admin user
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@yourcompany.com",
    "password": "secure-password",
    "first_name": "Admin",
    "last_name": "User"
  }'
```

### 3. Configure Ingress/Load Balancer

```bash
# Get load balancer URL
kubectl get ingress -n siem-plus

# Configure DNS
# Point your domain to the load balancer
```

### 4. SSL/TLS Certificates

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create ClusterIssuer
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@yourcompany.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

### 5. Configure Monitoring

```bash
# Access Grafana
kubectl port-forward svc/siem-plus-grafana 3000:80 -n siem-plus

# Login with admin credentials
# Import dashboards from /infra/grafana/dashboards/
```

## Scaling

### Horizontal Pod Autoscaling

```bash
# Check HPA status
kubectl get hpa -n siem-plus

# Manually scale
kubectl scale deployment siem-plus-detect --replicas=20 -n siem-plus
```

### Database Scaling

```bash
# For RDS (AWS)
aws rds modify-db-instance \
  --db-instance-identifier siem-plus-prod-db \
  --db-instance-class db.r6g.2xlarge \
  --apply-immediately
```

### OpenSearch Scaling

```bash
# Add more nodes
kubectl scale statefulset siem-plus-opensearch --replicas=5 -n siem-plus
```

## Backup & Disaster Recovery

### Database Backups

```bash
# Automated backups configured in Terraform
# Manual backup
kubectl exec -it deployment/siem-plus-manager -n siem-plus -- \
  pg_dump -h $DB_HOST -U siem_admin siem_plus > backup.sql
```

### OpenSearch Snapshots

```bash
# Configure S3 snapshot repository
curl -X PUT "http://opensearch:9200/_snapshot/s3_backup" \
  -H 'Content-Type: application/json' \
  -d '{
    "type": "s3",
    "settings": {
      "bucket": "siem-plus-backups",
      "region": "us-east-1"
    }
  }'

# Create snapshot
curl -X PUT "http://opensearch:9200/_snapshot/s3_backup/snapshot_1"
```

## Monitoring & Alerting

### Key Metrics to Monitor

- **Manager API**: Request rate, latency, error rate
- **Detection Engine**: Events/sec, alerts/sec, rule evaluation time
- **Kafka**: Lag, throughput, partition health
- **OpenSearch**: Cluster health, query latency, indexing rate
- **PostgreSQL**: Connections, query time, replication lag

### Alert Rules

```yaml
# Prometheus alert rules
groups:
  - name: siem-plus
    rules:
      - alert: HighDetectionLatency
        expr: detection_latency_seconds > 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Detection latency is high"

      - alert: KafkaConsumerLag
        expr: kafka_consumer_lag > 10000
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Kafka consumer lag is high"
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -n siem-plus
kubectl describe pod <pod-name> -n siem-plus
kubectl logs <pod-name> -n siem-plus
```

### Check Service Connectivity

```bash
# Test manager API
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://siem-plus-manager:8080/health

# Test database
kubectl run -it --rm debug --image=postgres --restart=Never -- \
  psql -h siem-plus-postgresql -U siem_admin -d siem_plus
```

### Performance Issues

```bash
# Check resource usage
kubectl top pods -n siem-plus
kubectl top nodes

# Check HPA status
kubectl describe hpa -n siem-plus
```

## Security Hardening

1. **Enable Pod Security Policies**
2. **Configure Network Policies**
3. **Use Secrets Management** (Vault, AWS Secrets Manager)
4. **Enable mTLS** between services
5. **Regular security updates**
6. **Audit logging enabled**

## Maintenance

### Rolling Updates

```bash
# Update manager
kubectl set image deployment/siem-plus-manager \
  manager=siem-plus/manager:0.2.0 \
  -n siem-plus

# Check rollout status
kubectl rollout status deployment/siem-plus-manager -n siem-plus

# Rollback if needed
kubectl rollout undo deployment/siem-plus-manager -n siem-plus
```

### Database Maintenance

```bash
# Vacuum and analyze
kubectl exec -it deployment/siem-plus-manager -n siem-plus -- \
  psql -c "VACUUM ANALYZE;"
```

## Cost Optimization

1. **Use spot instances** for detection workers
2. **Configure autoscaling** properly
3. **Implement data lifecycle policies** (hot/warm/cold)
4. **Use reserved instances** for baseline capacity
5. **Monitor and optimize** OpenSearch shard allocation
