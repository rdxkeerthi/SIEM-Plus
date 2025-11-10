# Complete SIEM-Plus Production Deployment for Windows

Write-Host "🚀 SIEM-Plus Complete Production Deployment" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""

$ErrorActionPreference = "Stop"

# Step 1: Deploy to Kubernetes
Write-Host "Step 1/5: Deploying to Kubernetes..." -ForegroundColor Yellow
.\scripts\deploy-kubernetes.ps1
Write-Host "✅ Kubernetes deployment complete" -ForegroundColor Green
Write-Host ""

# Wait for pods
Write-Host "Waiting for pods to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Step 2: Configure Integrations
Write-Host "Step 2/5: Configuring integrations..." -ForegroundColor Yellow
Write-Host "⚠️  Run configure-integrations.sh manually for interactive setup" -ForegroundColor Yellow
Write-Host ""

# Step 3: Import Sigma Rules
Write-Host "Step 3/5: Importing Sigma rules..." -ForegroundColor Yellow
Write-Host "⚠️  Run import-sigma-rules.sh manually (requires git)" -ForegroundColor Yellow
Write-Host ""

# Step 4: Setup Monitoring
Write-Host "Step 4/5: Setting up monitoring..." -ForegroundColor Yellow
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack `
    --namespace=monitoring `
    --create-namespace `
    --set grafana.adminPassword=admin `
    --wait
Write-Host "✅ Monitoring configured" -ForegroundColor Green
Write-Host ""

# Step 5: Scale Deployment
Write-Host "Step 5/5: Scaling deployment..." -ForegroundColor Yellow
$Namespace = "siem-plus"
kubectl scale deployment siem-plus-detect --replicas=10 -n $Namespace
kubectl scale deployment siem-plus-manager --replicas=5 -n $Namespace
Write-Host "✅ Deployment scaled" -ForegroundColor Green
Write-Host ""

# Final Status
Write-Host "=========================================" -ForegroundColor Green
Write-Host "✅ SIEM-Plus Production Deployment Complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Service Status:" -ForegroundColor Cyan
kubectl get pods -n $Namespace
Write-Host ""

Write-Host "Access Points:" -ForegroundColor Cyan
Write-Host "=============="
Write-Host "🌐 UI: Check LoadBalancer IP with: kubectl get svc -n $Namespace"
Write-Host "📊 Grafana: kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring"
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "==========="
Write-Host "1. Access the UI and change default password"
Write-Host "2. Deploy agents to your endpoints"
Write-Host "3. Configure custom detection rules"
Write-Host "4. Set up alert notifications"
Write-Host "5. Review Grafana dashboards"
