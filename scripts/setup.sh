#!/bin/bash
# SIEM-Plus Setup Script

set -e

echo "🚀 Setting up SIEM-Plus development environment..."

# Check prerequisites
command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required but not installed."; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { echo "❌ Docker Compose is required but not installed."; exit 1; }

# Start infrastructure
echo "📦 Starting infrastructure services..."
cd infra
docker-compose -f docker-compose.dev.yml up -d

echo "⏳ Waiting for services to be ready..."
sleep 30

# Check services
echo "✅ Checking service health..."
curl -s http://localhost:9200/_cluster/health || echo "⚠️  OpenSearch not ready"
curl -s http://localhost:9092 || echo "⚠️  Kafka not ready"

echo ""
echo "✨ Setup complete!"
echo ""
echo "Services running:"
echo "  - OpenSearch: http://localhost:9200"
echo "  - Kafka: localhost:9092"
echo "  - PostgreSQL: localhost:5432"
echo "  - Redis: localhost:6379"
echo "  - Grafana: http://localhost:3000"
echo ""
echo "Next steps:"
echo "  1. cd manager && go run ./cmd/server"
echo "  2. cd detect && cargo run --release"
echo "  3. cd ui && npm install && npm run dev"
echo ""
echo "Default credentials:"
echo "  Email: admin@siem-plus.io"
echo "  Password: admin123"
