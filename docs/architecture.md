# SIEM-Plus Architecture

Complete architecture documentation for SIEM-Plus security platform.

## System Components

1. **Agent (Rust)** - Endpoint monitoring
2. **Ingestion (Kafka)** - Event streaming
3. **Detection Engine (Rust)** - Sigma rule evaluation
4. **Storage (OpenSearch + PostgreSQL)** - Data persistence
5. **Manager API (Go)** - Control plane
6. **SOAR (Python)** - Automation
7. **UI (React)** - User interface

## Data Flow

Agent → Kafka → Detection → OpenSearch/PostgreSQL → API → UI

## Scalability

- Horizontal scaling via Kubernetes
- Kafka partitioning by tenant
- OpenSearch sharding
- Stateless services

## Security

- mTLS for internal communication
- JWT authentication
- RBAC authorization
- Multi-tenant isolation
