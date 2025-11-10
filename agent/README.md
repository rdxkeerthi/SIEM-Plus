# SIEM-Plus Agent

Lightweight, cross-platform endpoint security agent written in Rust.

## Features

- **File Integrity Monitoring (FIM)**: Real-time file change detection with cryptographic hashing
- **Process Monitoring**: Track process creation, termination, and suspicious activities
- **Network Monitoring**: Connection tracking and network flow analysis
- **System Telemetry**: CPU, memory, disk, and system metrics
- **Live Interrogation**: Remote query execution (osquery-like capabilities)
- **Secure Communication**: mTLS with certificate pinning
- **Auto-Update**: Signed binary updates with rollback capability
- **Low Overhead**: Minimal CPU and memory footprint (<50MB RAM, <2% CPU)

## Installation

### Linux (Debian/Ubuntu)

```bash
wget https://releases.siem-plus.io/agent/latest/siem-agent_amd64.deb
sudo dpkg -i siem-agent_amd64.deb
sudo systemctl start siem-agent
```

### Windows

```powershell
# Download and run MSI installer
Invoke-WebRequest -Uri "https://releases.siem-plus.io/agent/latest/siem-agent_x64.msi" -OutFile "siem-agent.msi"
msiexec /i siem-agent.msi /qn
```

### macOS

```bash
brew tap siem-plus/tap
brew install siem-agent
brew services start siem-agent
```

## Configuration

Configuration file location:
- Linux: `/etc/siem-agent/config.yaml`
- Windows: `C:\Program Files\SIEM-Plus\Agent\config.yaml`
- macOS: `/usr/local/etc/siem-agent/config.yaml`

### Example Configuration

```yaml
# Manager connection
manager:
  url: "https://manager.siem-plus.io"
  tenant_id: "your-tenant-id"
  agent_key: "${AGENT_KEY}"  # Use env var for secrets
  
# TLS settings
tls:
  verify_server: true
  ca_cert: "/etc/siem-agent/ca.crt"
  client_cert: "/etc/siem-agent/agent.crt"
  client_key: "/etc/siem-agent/agent.key"

# File Integrity Monitoring
fim:
  enabled: true
  paths:
    - path: "/etc"
      recursive: true
      exclude: ["*.log", "*.tmp"]
    - path: "/usr/bin"
      recursive: false
  scan_interval: 300  # seconds
  hash_algorithm: "blake3"

# Process Monitoring
procmon:
  enabled: true
  track_network: true
  track_file_access: true

# Network Monitoring
netmon:
  enabled: true
  track_connections: true
  track_dns: true

# Telemetry
telemetry:
  enabled: true
  interval: 60  # seconds
  metrics:
    - cpu
    - memory
    - disk
    - network

# Logging
logging:
  level: "info"  # trace, debug, info, warn, error
  format: "json"
  output: "/var/log/siem-agent/agent.log"

# Performance
performance:
  max_memory_mb: 100
  max_cpu_percent: 5
  batch_size: 100
  flush_interval: 10
```

## Building from Source

### Prerequisites

- Rust 1.70+
- OpenSSL development libraries (Linux)

### Build

```bash
cargo build --release
```

### Run Tests

```bash
cargo test
cargo clippy
```

### Cross-Compilation

```bash
# Linux to Windows
cargo build --release --target x86_64-pc-windows-gnu

# Linux to macOS (requires osxcross)
cargo build --release --target x86_64-apple-darwin
```

## Development

### Project Structure

```
src/
├── main.rs              # Entry point
├── config.rs            # Configuration management
├── telemetry/           # System metrics collection
│   ├── mod.rs
│   ├── cpu.rs
│   ├── memory.rs
│   └── disk.rs
├── fim/                 # File Integrity Monitoring
│   ├── mod.rs
│   ├── watcher.rs
│   └── hasher.rs
├── procmon/             # Process monitoring
│   ├── mod.rs
│   └── tracker.rs
├── network/             # Network monitoring
│   ├── mod.rs
│   └── connections.rs
├── uploader/            # Event batching and upload
│   ├── mod.rs
│   └── batch.rs
├── op/                  # Live operations (remote queries)
│   ├── mod.rs
│   └── executor.rs
├── crypto/              # Cryptography utilities
│   ├── mod.rs
│   └── signing.rs
└── platform/            # OS-specific implementations
    ├── mod.rs
    ├── windows.rs
    ├── linux.rs
    └── macos.rs
```

### Adding a New Module

1. Create module directory under `src/`
2. Implement module trait
3. Add module to `main.rs`
4. Add tests in `tests/`
5. Update documentation

## Performance Tuning

### Memory Usage

- Adjust `batch_size` to control memory buffering
- Set `max_memory_mb` to enforce hard limit
- Use `flush_interval` to control batch frequency

### CPU Usage

- Increase `scan_interval` for FIM to reduce overhead
- Disable unused modules
- Adjust `telemetry.interval` for less frequent metrics

### Network Usage

- Increase `batch_size` to reduce HTTP requests
- Enable compression in uploader
- Use local buffering for offline scenarios

## Troubleshooting

### Agent Not Starting

```bash
# Check logs
tail -f /var/log/siem-agent/agent.log

# Verify configuration
siem-agent --config /etc/siem-agent/config.yaml --validate

# Test connectivity
siem-agent --test-connection
```

### High CPU Usage

```bash
# Check current resource usage
siem-agent --status

# Enable debug logging
siem-agent --log-level debug
```

### Connection Issues

```bash
# Verify TLS certificates
openssl verify -CAfile /etc/siem-agent/ca.crt /etc/siem-agent/agent.crt

# Test manager connectivity
curl -v --cacert /etc/siem-agent/ca.crt https://manager.siem-plus.io/health
```

## Security

- Agent runs with minimal privileges (drops root after binding ports)
- All communication uses mTLS
- Binaries are code-signed
- Configuration secrets can use environment variables
- Automatic security updates

## License

Apache 2.0 - See LICENSE file
