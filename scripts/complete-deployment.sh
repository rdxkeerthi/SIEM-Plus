#!/bin/bash
# Complete SIEM-Plus Production Deployment

set -e

echo "🚀 SIEM-Plus Complete Production Deployment"
echo "============================================"
echo ""

# Step 1: Deploy to Kubernetes
echo "Step 1/5: Deploying to Kubernetes..."
./scripts/deploy-kubernetes.sh
echo "✅ Kubernetes deployment complete"
echo ""

# Wait for pods to be ready
echo "Waiting for all pods to be ready..."
sleep 30

# Step 2: Configure Integrations
echo "Step 2/5: Configuring integrations..."
./scripts/configure-integrations.sh
echo "✅ Integrations configured"
echo ""

# Step 3: Import Sigma Rules
echo "Step 3/5: Importing Sigma detection rules..."
./scripts/import-sigma-rules.sh
echo "✅ Sigma rules imported"
echo ""

# Step 4: Setup Monitoring
echo "Step 4/5: Setting up monitoring..."
./scripts/setup-monitoring.sh
echo "✅ Monitoring configured"
echo ""

# Step 5: Scale Deployment
echo "Step 5/5: Scaling deployment..."
./scripts/scale-deployment.sh
echo "✅ Deployment scaled"
echo ""

# Final Status
echo "========================================="
echo "✅ SIEM-Plus Production Deployment Complete!"
echo "========================================="
echo ""

# Get service endpoints
NAMESPACE="${NAMESPACE:-siem-plus}"
echo "Service Status:"
kubectl get pods -n $NAMESPACE
echo ""

echo "Access Points:"
echo "=============="
LB_IP=$(kubectl get svc siem-plus-ui -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
LB_HOST=$(kubectl get svc siem-plus-ui -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)

if [ -n "$LB_IP" ]; then
    echo "🌐 UI: http://$LB_IP"
    echo "🔌 API: http://$LB_IP/api/v1"
elif [ -n "$LB_HOST" ]; then
    echo "🌐 UI: http://$LB_HOST"
    echo "🔌 API: http://$LB_HOST/api/v1"
fi

echo "📊 Grafana: kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring"
echo ""

echo "Next Steps:"
echo "==========="
echo "1. Access the UI and change default password"
echo "2. Deploy agents to your endpoints"
echo "3. Configure custom detection rules"
echo "4. Set up alert notifications"
echo "5. Review Grafana dashboards"
echo ""

echo "Documentation:"
echo "=============="
echo "📖 Full docs: https://github.com/rdxkeerthi/SIEM-Plus"
echo "📘 Deployment: docs/deployment.md"
echo "📗 API Reference: docs/api-reference.md"
