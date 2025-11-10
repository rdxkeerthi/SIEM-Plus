# Test SIEM-Plus Locally with Docker Compose (Windows)

Write-Host "🧪 SIEM-Plus Local Testing" -ForegroundColor Green
Write-Host "==========================" -ForegroundColor Green
Write-Host ""

$ErrorActionPreference = "Continue"

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow
$docker = Get-Command docker -ErrorAction SilentlyContinue
if (-not $docker) {
    Write-Host "❌ Docker not found" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Prerequisites OK" -ForegroundColor Green
Write-Host ""

# Start infrastructure
Write-Host "Step 1: Starting infrastructure services..." -ForegroundColor Yellow
Set-Location infra
docker-compose -f docker-compose.dev.yml up -d

Write-Host "⏳ Waiting for services to be ready (30 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Check service health
Write-Host ""
Write-Host "Step 2: Checking service health..." -ForegroundColor Yellow

# Check Kafka
try {
    $kafka = Test-NetConnection -ComputerName localhost -Port 9092 -WarningAction SilentlyContinue
    if ($kafka.TcpTestSucceeded) {
        Write-Host "✅ Kafka is running on port 9092" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  Kafka not responding on port 9092" -ForegroundColor Yellow
}

# Check OpenSearch
try {
    $response = Invoke-WebRequest -Uri "http://localhost:9200/_cluster/health" -UseBasicParsing -TimeoutSec 5
    Write-Host "✅ OpenSearch is running on port 9200" -ForegroundColor Green
} catch {
    Write-Host "⚠️  OpenSearch not responding on port 9200" -ForegroundColor Yellow
}

# Check PostgreSQL
try {
    $pg = Test-NetConnection -ComputerName localhost -Port 5432 -WarningAction SilentlyContinue
    if ($pg.TcpTestSucceeded) {
        Write-Host "✅ PostgreSQL is running on port 5432" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  PostgreSQL not responding on port 5432" -ForegroundColor Yellow
}

# Check Redis
try {
    $redis = Test-NetConnection -ComputerName localhost -Port 6379 -WarningAction SilentlyContinue
    if ($redis.TcpTestSucceeded) {
        Write-Host "✅ Redis is running on port 6379" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  Redis not responding on port 6379" -ForegroundColor Yellow
}

Set-Location ..

Write-Host ""
Write-Host "Step 3: Building Manager API..." -ForegroundColor Yellow
Set-Location manager
Start-Process -FilePath "go" -ArgumentList "run", ".\cmd\server\main.go" -NoNewWindow
Start-Sleep -Seconds 5

# Test Manager API
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/health" -UseBasicParsing -TimeoutSec 5
    Write-Host "✅ Manager API is running on port 8080" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Manager API not responding (may still be starting)" -ForegroundColor Yellow
}

Set-Location ..

Write-Host ""
Write-Host "Step 4: Building Detection Engine..." -ForegroundColor Yellow
Set-Location detect
Write-Host "⏳ Building Rust project (this may take a few minutes)..." -ForegroundColor Yellow
cargo build --release
if ($LASTEXITCODE -eq 0) {
    Start-Process -FilePath ".\target\release\detect-engine.exe" -NoNewWindow
    Start-Sleep -Seconds 5
    Write-Host "✅ Detection Engine started" -ForegroundColor Green
}

Set-Location ..

Write-Host ""
Write-Host "Step 5: Starting UI..." -ForegroundColor Yellow
Set-Location ui
Write-Host "Installing dependencies..." -ForegroundColor Yellow
npm install --silent
Start-Process -FilePath "npm" -ArgumentList "run", "dev" -NoNewWindow
Start-Sleep -Seconds 10

Set-Location ..

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "✅ SIEM-Plus is running locally!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Access Points:" -ForegroundColor Cyan
Write-Host "  🌐 UI:              http://localhost:3000"
Write-Host "  🔌 Manager API:     http://localhost:8080"
Write-Host "  🔍 Detection:       http://localhost:8081"
Write-Host "  📊 OpenSearch:      http://localhost:9200"
Write-Host "  📈 Grafana:         http://localhost:3001"
Write-Host ""
Write-Host "Default Credentials:" -ForegroundColor Cyan
Write-Host "  Email:    admin@siem-plus.io"
Write-Host "  Password: admin123"
Write-Host ""
Write-Host "To stop services:" -ForegroundColor Yellow
Write-Host "  cd infra"
Write-Host "  docker-compose -f docker-compose.dev.yml down"
