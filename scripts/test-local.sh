#!/bin/bash
# Test SIEM-Plus Locally with Docker Compose

set -e

echo "🧪 SIEM-Plus Local Testing"
echo "=========================="
echo ""

# Check prerequisites
echo "Checking prerequisites..."
command -v docker >/dev/null 2>&1 || { echo "❌ Docker not found"; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { echo "❌ Docker Compose not found"; exit 1; }
echo "✅ Prerequisites OK"
echo ""

# Start infrastructure
echo "Step 1: Starting infrastructure services..."
cd infra
docker-compose -f docker-compose.dev.yml up -d

echo "⏳ Waiting for services to be ready (30 seconds)..."
sleep 30

# Check service health
echo ""
echo "Step 2: Checking service health..."

# Check Kafka
if nc -z localhost 9092 2>/dev/null; then
    echo "✅ Kafka is running on port 9092"
else
    echo "⚠️  Kafka not responding on port 9092"
fi

# Check OpenSearch
if curl -s http://localhost:9200/_cluster/health >/dev/null 2>&1; then
    echo "✅ OpenSearch is running on port 9200"
else
    echo "⚠️  OpenSearch not responding on port 9200"
fi

# Check PostgreSQL
if nc -z localhost 5432 2>/dev/null; then
    echo "✅ PostgreSQL is running on port 5432"
else
    echo "⚠️  PostgreSQL not responding on port 5432"
fi

# Check Redis
if nc -z localhost 6379 2>/dev/null; then
    echo "✅ Redis is running on port 6379"
else
    echo "⚠️  Redis not responding on port 6379"
fi

cd ..

echo ""
echo "Step 3: Building and starting Manager API..."
cd manager
go build -o manager ./cmd/server &
MANAGER_PID=$!
sleep 5

# Test Manager API
if curl -s http://localhost:8080/health >/dev/null 2>&1; then
    echo "✅ Manager API is running on port 8080"
else
    echo "⚠️  Manager API not responding"
fi

cd ..

echo ""
echo "Step 4: Building and starting Detection Engine..."
cd detect
cargo build --release
./target/release/detect-engine &
DETECT_PID=$!
sleep 5

# Test Detection Engine
if curl -s http://localhost:8081/health >/dev/null 2>&1; then
    echo "✅ Detection Engine is running on port 8081"
else
    echo "⚠️  Detection Engine not responding"
fi

cd ..

echo ""
echo "Step 5: Starting UI..."
cd ui
npm install --silent
npm run dev &
UI_PID=$!
sleep 10

echo ""
echo "========================================="
echo "✅ SIEM-Plus is running locally!"
echo "========================================="
echo ""
echo "Access Points:"
echo "  🌐 UI:              http://localhost:3000"
echo "  🔌 Manager API:     http://localhost:8080"
echo "  🔍 Detection:       http://localhost:8081"
echo "  📊 OpenSearch:      http://localhost:9200"
echo "  📈 Grafana:         http://localhost:3001"
echo "  🔧 Prometheus:      http://localhost:9090"
echo ""
echo "Default Credentials:"
echo "  Email:    admin@siem-plus.io"
echo "  Password: admin123"
echo ""
echo "Press Ctrl+C to stop all services"
echo ""

# Wait for interrupt
trap "echo ''; echo 'Stopping services...'; kill $MANAGER_PID $DETECT_PID $UI_PID 2>/dev/null; cd infra; docker-compose -f docker-compose.dev.yml down; echo '✅ All services stopped'; exit 0" INT TERM

wait
