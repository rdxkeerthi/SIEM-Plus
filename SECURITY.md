# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to: **security@siem-plus.io**

Include the following information:

- Type of issue (e.g., buffer overflow, SQL injection, cross-site scripting)
- Full paths of source file(s) related to the issue
- Location of the affected source code (tag/branch/commit or direct URL)
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

## Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Fix Timeline**: Depends on severity (critical: 7-14 days, high: 30 days)

## Security Update Process

1. Security team validates the report
2. Fix is developed in a private repository
3. CVE is requested (if applicable)
4. Security advisory is prepared
5. Fix is released with security advisory
6. Public disclosure after users have time to update

## Security Best Practices

### For Deployments

- Use mTLS for all internal communications
- Enable authentication and RBAC
- Rotate secrets regularly
- Keep all components updated
- Monitor security advisories
- Use signed agent binaries only
- Implement network segmentation
- Enable audit logging

### For Development

- Never commit secrets to version control
- Use dependency scanning tools
- Run security linters (cargo-audit, gosec, npm audit)
- Validate all inputs
- Use parameterized queries
- Implement rate limiting
- Follow principle of least privilege

## Known Security Considerations

- **Agent Security**: Agents run with elevated privileges; ensure proper code signing
- **Multi-Tenancy**: Strict tenant isolation is critical; validate all tenant boundaries
- **Rule Execution**: Sigma rules run in sandboxed environment to prevent code injection
- **API Authentication**: All APIs require authentication; use short-lived tokens
- **Data Encryption**: Encrypt data at rest and in transit

## Security Features

- **Signed Binaries**: All agent binaries are code-signed
- **Immutable Audit Logs**: Tamper-evident logging with hash chains
- **RBAC**: Role-based access control with fine-grained permissions
- **SSO/OIDC**: Enterprise authentication integration
- **MFA**: Multi-factor authentication support
- **Secrets Management**: Integration with HashiCorp Vault
- **Network Policies**: Kubernetes network policies for pod isolation

## Compliance

SIEM-Plus is designed to support:

- SOC 2 Type II
- ISO 27001
- GDPR
- HIPAA (with proper configuration)
- PCI DSS

## Bug Bounty

We are planning to launch a bug bounty program. Details will be announced soon.

## Contact

- Security Team: security@siem-plus.io
- PGP Key: [Link to public key]
