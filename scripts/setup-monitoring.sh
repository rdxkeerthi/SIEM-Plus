#!/bin/bash
# Setup Grafana Monitoring for SIEM-Plus

set -e

echo "📊 SIEM-Plus Monitoring Setup"
NAMESPACE="${NAMESPACE:-siem-plus}"

# Install Prometheus Operator
echo "Installing Prometheus Operator..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace=monitoring \
    --create-namespace \
    --set grafana.adminPassword=admin \
    --wait

echo "✅ Prometheus installed"

# Import Grafana dashboards
echo "Importing Grafana dashboards..."
kubectl create configmap grafana-dashboards \
    --from-file=infra/grafana/dashboards/ \
    --namespace=monitoring \
    --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Monitoring setup complete"
echo "Access Grafana: kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring"
