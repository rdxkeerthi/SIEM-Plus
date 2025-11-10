.PHONY: help build test lint clean dev-up dev-down run-manager run-ui docker-build

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build all components
	@echo "Building agent..."
	cd agent && cargo build --release
	@echo "Building ingest..."
	cd ingest && go build -o bin/ingest-worker ./cmd/worker
	@echo "Building detect..."
	cd detect && cargo build --release
	@echo "Building manager..."
	cd manager && go build -o bin/manager ./cmd/server
	@echo "Building UI..."
	cd ui && npm run build
	@echo "Building SOAR..."
	cd soar && pip install -e .

test: ## Run all tests
	cd agent && cargo test
	cd ingest && go test ./...
	cd detect && cargo test
	cd manager && go test ./...
	cd ui && npm test
	cd soar && pytest

lint: ## Run linters
	cd agent && cargo clippy -- -D warnings
	cd ingest && golangci-lint run
	cd detect && cargo clippy -- -D warnings
	cd manager && golangci-lint run
	cd ui && npm run lint
	cd soar && pylint soar/

clean: ## Clean build artifacts
	cd agent && cargo clean
	cd ingest && rm -rf bin/
	cd detect && cargo clean
	cd manager && rm -rf bin/
	cd ui && rm -rf build/ dist/
	cd soar && rm -rf build/ dist/ *.egg-info

dev-up: ## Start local dev stack (Kafka, OpenSearch, Redis)
	docker-compose -f infra/docker-compose.dev.yml up -d
	@echo "Waiting for services to be ready..."
	@sleep 10
	@echo "Dev stack ready!"
	@echo "  OpenSearch: http://localhost:9200"
	@echo "  Kafka: localhost:9092"
	@echo "  Redis: localhost:6379"

dev-down: ## Stop local dev stack
	docker-compose -f infra/docker-compose.dev.yml down

dev-logs: ## Show dev stack logs
	docker-compose -f infra/docker-compose.dev.yml logs -f

run-manager: ## Run manager API server
	cd manager && go run ./cmd/server

run-ui: ## Run UI dev server
	cd ui && npm start

run-detect: ## Run detection engine
	cd detect && cargo run --release

docker-build: ## Build all Docker images
	docker build -t siem-plus/agent:latest -f agent/Dockerfile .
	docker build -t siem-plus/ingest:latest -f ingest/Dockerfile .
	docker build -t siem-plus/detect:latest -f detect/Dockerfile .
	docker build -t siem-plus/manager:latest -f manager/Dockerfile .
	docker build -t siem-plus/ui:latest -f ui/Dockerfile .
	docker build -t siem-plus/soar:latest -f soar/Dockerfile .

install-tools: ## Install development tools
	cargo install cargo-audit cargo-watch
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	npm install -g prettier eslint
	pip install pylint pytest black

setup-dev: ## Setup development environment
	@echo "Setting up development environment..."
	cd agent && cargo build
	cd ingest && go mod download
	cd detect && cargo build
	cd manager && go mod download
	cd ui && npm install
	cd soar && pip install -r requirements.txt
	@echo "Development environment ready!"
