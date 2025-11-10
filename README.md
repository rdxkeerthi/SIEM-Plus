# SIEM-Plus

**A next-generation Security Information and Event Management platform with enhanced detection, EDR capabilities, and SOAR automation.**

## 🚀 Features

- **Sigma-First Detection**: Native Sigma rule support with stream-based detection engine
- **Lightweight Rust Agent**: Cross-platform endpoint agent with FIM, process monitoring, and live interrogation
- **Stream Processing**: Real-time event correlation and stateful detection
- **SOAR Integration**: Automated playbooks and incident response workflows
- **Multi-Tenancy**: Enterprise-ready with RBAC and tenant isolation
- **Modern UI**: React-based dashboard with GraphQL API
- **Scalable Architecture**: Kubernetes-native with horizontal scaling

## 📁 Repository Structure

```
/
├── agent/          # Rust endpoint agent
├── ingest/         # Event ingestion pipeline (Go/Rust)
├── detect/         # Stream detection engine + Sigma compiler
├── indexer/        # OpenSearch templates & lifecycle management
├── manager/        # Control plane APIs (Go/TypeScript)
├── ui/             # React dashboard + GraphQL
├── soar/           # Playbook engine + connectors (Python)
├── infra/          # Terraform + Helm + k8s manifests
├── marketplace/    # Curated Sigma rule packs
├── docs/           # Architecture & API documentation
└── scripts/        # DevOps & release tooling
```

## 🏗️ Quick Start

### Prerequisites

- Docker & Docker Compose
- Rust 1.70+
- Go 1.21+
- Node.js 18+
- Python 3.11+
- kubectl & helm (for k8s deployment)

### Local Development

```bash
# Start local dev stack (Kafka, OpenSearch, Redis)
make dev-up

# Build all components
make build

# Run tests
make test

# Start manager API
make run-manager

# Start UI dev server
make run-ui
```

### Deploy to Kubernetes

```bash
cd infra/helm-charts
helm install siem-plus ./siem-plus -f values-prod.yaml
```

## 📚 Documentation

- [Architecture Overview](docs/architecture.md)
- [Getting Started Guide](docs/getting-started.md)
- [Agent Deployment](docs/agent-deployment.md)
- [Sigma Rule Development](docs/sigma-rules.md)
- [API Reference](docs/api-reference.md)
- [Security & Compliance](docs/security.md)

## 🔒 Security

- mTLS for all internal communications
- Signed agent binaries with verification
- Immutable audit logs with hash chains
- SSO/OIDC integration with MFA support
- Secrets management via HashiCorp Vault

## 🛠️ Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## 📝 License

[Apache 2.0](LICENSE)

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md).

## 📧 Contact

- Issues: [GitHub Issues](https://github.com/your-org/siem-plus/issues)
- Security: security@siem-plus.io
- Docs: https://docs.siem-plus.io
