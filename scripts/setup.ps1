# SIEM-Plus Setup Script for Windows

Write-Host "🚀 Setting up SIEM-Plus development environment..." -ForegroundColor Green

# Check prerequisites
$dockerInstalled = Get-Command docker -ErrorAction SilentlyContinue
if (-not $dockerInstalled) {
    Write-Host "❌ Docker is required but not installed." -ForegroundColor Red
    exit 1
}

# Start infrastructure
Write-Host "📦 Starting infrastructure services..." -ForegroundColor Yellow
Set-Location infra
docker-compose -f docker-compose.dev.yml up -d

Write-Host "⏳ Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Check services
Write-Host "✅ Checking service health..." -ForegroundColor Green
try {
    Invoke-WebRequest -Uri "http://localhost:9200/_cluster/health" -UseBasicParsing | Out-Null
} catch {
    Write-Host "⚠️  OpenSearch not ready" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✨ Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Services running:" -ForegroundColor Cyan
Write-Host "  - OpenSearch: http://localhost:9200"
Write-Host "  - Kafka: localhost:9092"
Write-Host "  - PostgreSQL: localhost:5432"
Write-Host "  - Redis: localhost:6379"
Write-Host "  - Grafana: http://localhost:3000"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. cd manager && go run ./cmd/server"
Write-Host "  2. cd detect && cargo run --release"
Write-Host "  3. cd ui && npm install && npm run dev"
Write-Host ""
Write-Host "Default credentials:" -ForegroundColor Yellow
Write-Host "  Email: admin@siem-plus.io"
Write-Host "  Password: admin123"
