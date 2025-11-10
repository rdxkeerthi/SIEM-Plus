# SIEM-Plus Kubernetes Deployment Script for Windows

param(
    [string]$Namespace = "siem-plus",
    [string]$ReleaseName = "siem-plus",
    [string]$ValuesFile = "values-prod.yaml"
)

Write-Host "🚀 SIEM-Plus Kubernetes Deployment" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green

# Check prerequisites
Write-Host "`nChecking prerequisites..." -ForegroundColor Yellow

$kubectl = Get-Command kubectl -ErrorAction SilentlyContinue
if (-not $kubectl) {
    Write-Host "❌ kubectl not found. Please install kubectl." -ForegroundColor Red
    exit 1
}

$helm = Get-Command helm -ErrorAction SilentlyContinue
if (-not $helm) {
    Write-Host "❌ helm not found. Please install Helm 3." -ForegroundColor Red
    exit 1
}

# Check cluster connectivity
try {
    kubectl cluster-info | Out-Null
} catch {
    Write-Host "❌ Cannot connect to Kubernetes cluster." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Prerequisites check passed" -ForegroundColor Green

# Create namespace
Write-Host "`nCreating namespace: $Namespace" -ForegroundColor Yellow
kubectl create namespace $Namespace --dry-run=client -o yaml | kubectl apply -f -

# Create secrets
Write-Host "`nCreating secrets..." -ForegroundColor Yellow

$DBPassword = Read-Host "Enter PostgreSQL password" -AsSecureString
$DBPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($DBPassword)
)

$dbUrl = "postgres://siem_admin:$DBPasswordPlain@siem-plus-postgresql:5432/siem_plus?sslmode=disable"
kubectl create secret generic siem-plus-secrets `
    --from-literal=database-url="$dbUrl" `
    --namespace=$Namespace `
    --dry-run=client -o yaml | kubectl apply -f -

# JWT secret
$JWTSecret = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})
kubectl create secret generic siem-plus-jwt `
    --from-literal=jwt-secret="$JWTSecret" `
    --namespace=$Namespace `
    --dry-run=client -o yaml | kubectl apply -f -

Write-Host "✅ Secrets created" -ForegroundColor Green

# Add Helm repositories
Write-Host "`nAdding Helm repositories..." -ForegroundColor Yellow
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add opensearch https://opensearch-project.github.io/helm-charts/
helm repo update

Write-Host "✅ Helm repositories updated" -ForegroundColor Green

# Deploy SIEM-Plus
Write-Host "`nDeploying SIEM-Plus..." -ForegroundColor Yellow

$chartPath = ".\infra\helm-charts\siem-plus"

if (Test-Path $ValuesFile) {
    Write-Host "Using values file: $ValuesFile"
    helm upgrade --install $ReleaseName $chartPath `
        --namespace=$Namespace `
        --values=$ValuesFile `
        --wait `
        --timeout=10m
} else {
    Write-Host "Using default values"
    helm upgrade --install $ReleaseName $chartPath `
        --namespace=$Namespace `
        --wait `
        --timeout=10m
}

Write-Host "✅ SIEM-Plus deployed successfully" -ForegroundColor Green

# Wait for pods
Write-Host "`nWaiting for pods to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod `
    --selector=app.kubernetes.io/instance=$ReleaseName `
    --namespace=$Namespace `
    --timeout=5m

# Display info
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "SIEM-Plus Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`nService Endpoints:" -ForegroundColor Cyan
Write-Host "==================="

$services = kubectl get svc -n $Namespace -o json | ConvertFrom-Json
foreach ($svc in $services.items) {
    if ($svc.metadata.name -like "*ui*") {
        $ip = $svc.status.loadBalancer.ingress[0].ip
        $hostname = $svc.status.loadBalancer.ingress[0].hostname
        if ($ip) {
            Write-Host "UI: http://$ip" -ForegroundColor Green
        } elseif ($hostname) {
            Write-Host "UI: http://$hostname" -ForegroundColor Green
        }
    }
}

Write-Host "`nUseful Commands:" -ForegroundColor Cyan
Write-Host "================"
Write-Host "View pods:       kubectl get pods -n $Namespace"
Write-Host "View services:   kubectl get svc -n $Namespace"
Write-Host "View logs:       kubectl logs -f deployment/$ReleaseName-manager -n $Namespace"
Write-Host "Port forward:    kubectl port-forward svc/$ReleaseName-ui 8080:80 -n $Namespace"

Write-Host "`nDefault Credentials:" -ForegroundColor Cyan
Write-Host "===================="
Write-Host "Email:    admin@siem-plus.io"
Write-Host "Password: admin123"
Write-Host "`n⚠️  Remember to change default credentials!" -ForegroundColor Yellow
