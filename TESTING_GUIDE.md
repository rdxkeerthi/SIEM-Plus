# SIEM-Plus Testing Guide

## Quick Test (Local Development)

### Option 1: Automated Test Script (Recommended)

**Windows:**
```powershell
.\scripts\test-local.ps1
```

**Linux/Mac:**
```bash
chmod +x scripts/test-local.sh
./scripts/test-local.sh
```

This will:
1. Start all infrastructure services (Kafka, OpenSearch, PostgreSQL, Redis)
2. Build and start Manager API
3. Build and start Detection Engine
4. Start UI development server
5. Verify all services are healthy

### Option 2: Manual Step-by-Step

#### 1. Start Infrastructure
```bash
cd infra
docker-compose -f docker-compose.dev.yml up -d
```

Wait 30 seconds for services to initialize.

#### 2. Start Manager API
```bash
cd manager
go run ./cmd/server/main.go
```

Access: http://localhost:8080/health

#### 3. Start Detection Engine
```bash
cd detect
cargo run --release
```

Access: http://localhost:8081/health

#### 4. Start UI
```bash
cd ui
npm install
npm run dev
```

Access: http://localhost:3000

## Running Tests

### All Tests
```bash
chmod +x scripts/run-tests.sh
./scripts/run-tests.sh
```

### Individual Component Tests

**Agent Tests:**
```bash
cd agent
cargo test
```

**Detection Engine Tests:**
```bash
cd detect
cargo test
```

**Manager API Tests:**
```bash
cd manager
go test ./...
```

**UI Build Test:**
```bash
cd ui
npm run build
```

## Manual Testing Checklist

### 1. Infrastructure Health
- [ ] Kafka running on port 9092
- [ ] OpenSearch running on port 9200
- [ ] PostgreSQL running on port 5432
- [ ] Redis running on port 6379
- [ ] Grafana running on port 3001

### 2. API Testing

**Health Check:**
```bash
curl http://localhost:8080/health
```

**Register User:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!",
    "first_name": "Test",
    "last_name": "User"
  }'
```

**Login:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@siem-plus.io",
    "password": "admin123"
  }'
```

**Get Dashboard Stats:**
```bash
TOKEN="your-jwt-token"
curl http://localhost:8080/api/v1/dashboard/stats \
  -H "Authorization: Bearer $TOKEN"
```

### 3. Detection Engine Testing

**Check Health:**
```bash
curl http://localhost:8081/health
```

**View Metrics:**
```bash
curl http://localhost:8081/metrics
```

### 4. UI Testing
1. Navigate to http://localhost:3000
2. Login with admin@siem-plus.io / admin123
3. Verify dashboard loads
4. Check agents page
5. Check alerts page
6. Check rules page
7. Check cases page

### 5. End-to-End Test

**Send Test Event:**
```bash
TOKEN="your-jwt-token"
curl -X POST http://localhost:8080/api/v1/events \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "events": [{
      "timestamp": "2025-01-10T10:00:00Z",
      "event_type": "process_start",
      "hostname": "test-host",
      "process_name": "powershell.exe",
      "command_line": "powershell.exe -enc base64data"
    }]
  }'
```

This should trigger the "Suspicious PowerShell" detection rule.

## Performance Testing

### Load Test Manager API
```bash
# Install hey if not already installed
# go install github.com/rakyll/hey@latest

hey -n 1000 -c 10 http://localhost:8080/health
```

### Load Test Detection Engine
```bash
# Send 1000 events
for i in {1..1000}; do
  curl -X POST http://localhost:8080/api/v1/events \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"events":[{"event_type":"test"}]}' &
done
wait
```

## Monitoring During Tests

### View Logs

**Manager:**
```bash
tail -f manager/logs/manager.log
```

**Detection Engine:**
```bash
tail -f detect/logs/detect.log
```

**Docker Services:**
```bash
docker-compose -f infra/docker-compose.dev.yml logs -f
```

### Check Metrics

**Prometheus:**
- Navigate to http://localhost:9090
- Query: `events_processed_total`
- Query: `alerts_generated_total`

**Grafana:**
- Navigate to http://localhost:3001
- Login: admin / admin
- Import dashboard from `infra/grafana/dashboards/`

## Troubleshooting

### Services Not Starting

**Check Docker:**
```bash
docker ps
docker-compose -f infra/docker-compose.dev.yml ps
```

**Check Logs:**
```bash
docker-compose -f infra/docker-compose.dev.yml logs
```

### Port Already in Use

**Find Process:**
```bash
# Linux/Mac
lsof -i :8080

# Windows
netstat -ano | findstr :8080
```

**Kill Process:**
```bash
# Linux/Mac
kill -9 <PID>

# Windows
taskkill /PID <PID> /F
```

### Database Connection Issues

**Test PostgreSQL:**
```bash
docker exec -it siem-postgres psql -U siem_admin -d siem_plus
```

**Reset Database:**
```bash
docker-compose -f infra/docker-compose.dev.yml down -v
docker-compose -f infra/docker-compose.dev.yml up -d
```

### Build Failures

**Clean Rust Build:**
```bash
cd agent  # or detect
cargo clean
cargo build --release
```

**Clean Go Build:**
```bash
cd manager
go clean
go build ./cmd/server
```

**Clean Node Build:**
```bash
cd ui
rm -rf node_modules dist
npm install
npm run build
```

## Expected Results

### Successful Test Run
- ✅ All infrastructure services healthy
- ✅ Manager API responds on port 8080
- ✅ Detection Engine responds on port 8081
- ✅ UI loads on port 3000
- ✅ Login successful
- ✅ Dashboard displays stats
- ✅ All component tests pass

### Performance Benchmarks
- Manager API: >1000 req/sec
- Detection Engine: >10K events/sec
- UI Load Time: <2 seconds
- API Response Time: <50ms p95

## Cleanup

### Stop All Services
```bash
# Stop infrastructure
cd infra
docker-compose -f docker-compose.dev.yml down

# Stop running processes
pkill -f "go run"
pkill -f "cargo run"
pkill -f "npm run dev"
```

### Clean Everything
```bash
# Remove all containers and volumes
docker-compose -f infra/docker-compose.dev.yml down -v

# Clean build artifacts
cd agent && cargo clean
cd ../detect && cargo clean
cd ../manager && go clean
cd ../ui && rm -rf node_modules dist
```

## CI/CD Testing

Tests run automatically on every push via GitHub Actions:
- Agent build and test
- Detection Engine build and test
- Manager API build and test
- UI build and lint

View results: https://github.com/rdxkeerthi/SIEM-Plus/actions
