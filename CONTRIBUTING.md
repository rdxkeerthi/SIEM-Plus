# Contributing to SIEM-Plus

Thank you for your interest in contributing to SIEM-Plus! This document provides guidelines and instructions for contributing.

## 🌟 Ways to Contribute

- **Code**: Submit bug fixes, features, or improvements
- **Documentation**: Improve docs, add examples, fix typos
- **Rules**: Contribute Sigma detection rules
- **Testing**: Write tests, report bugs, test releases
- **Design**: UI/UX improvements and feedback

## 🚀 Getting Started

1. **Fork the repository**
2. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/siem-plus.git
   cd siem-plus
   ```
3. **Set up development environment**:
   ```bash
   make setup-dev
   make dev-up
   ```
4. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## 📝 Development Workflow

### Code Style

- **Rust**: Follow `rustfmt` and `clippy` recommendations
- **Go**: Use `gofmt` and follow [Effective Go](https://golang.org/doc/effective_go.html)
- **TypeScript/React**: Use Prettier and ESLint configs
- **Python**: Follow PEP 8, use Black formatter

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

Examples:
```
feat(agent): add network connection monitoring
fix(detect): resolve race condition in rule evaluation
docs(api): update authentication endpoints
```

### Testing

- Write tests for all new features
- Ensure all tests pass: `make test`
- Run linters: `make lint`
- Aim for >80% code coverage

### Pull Request Process

1. **Update documentation** for any changed functionality
2. **Add tests** for new features
3. **Run full test suite**: `make test`
4. **Update CHANGELOG.md** with your changes
5. **Submit PR** with clear description:
   - What problem does it solve?
   - How was it tested?
   - Any breaking changes?
6. **Address review feedback** promptly
7. **Squash commits** before merge (if requested)

## 🔒 Security

- **Never commit secrets** (API keys, passwords, certificates)
- **Report security issues** privately to security@siem-plus.io
- Follow our [Security Policy](SECURITY.md)

## 📋 Code Review Guidelines

### For Authors
- Keep PRs focused and reasonably sized (<500 lines when possible)
- Provide context in PR description
- Respond to feedback constructively
- Update PR based on review comments

### For Reviewers
- Be respectful and constructive
- Focus on code quality, security, and maintainability
- Test the changes locally when possible
- Approve only when all concerns are addressed

## 🏗️ Architecture Guidelines

- **Modularity**: Keep components loosely coupled
- **Performance**: Profile before optimizing, avoid premature optimization
- **Security**: Defense in depth, validate all inputs
- **Observability**: Add metrics, logs, and traces
- **Documentation**: Document public APIs and complex logic

## 🧪 Testing Standards

### Unit Tests
- Test individual functions and methods
- Mock external dependencies
- Fast execution (<1s per test file)

### Integration Tests
- Test component interactions
- Use test containers for dependencies
- Clean up resources after tests

### End-to-End Tests
- Test complete user workflows
- Run in CI before release
- Document test scenarios

## 📚 Documentation

- Update relevant docs in `docs/` directory
- Add inline code comments for complex logic
- Include examples for new features
- Keep API documentation current

## 🎯 Issue Guidelines

### Reporting Bugs

Include:
- **Description**: Clear description of the bug
- **Steps to reproduce**: Minimal reproduction steps
- **Expected behavior**: What should happen
- **Actual behavior**: What actually happens
- **Environment**: OS, versions, configuration
- **Logs**: Relevant error messages or logs

### Feature Requests

Include:
- **Use case**: Why is this feature needed?
- **Proposed solution**: How should it work?
- **Alternatives**: Other approaches considered
- **Additional context**: Screenshots, examples

## 🏷️ Labels

- `bug`: Something isn't working
- `enhancement`: New feature or request
- `documentation`: Documentation improvements
- `good first issue`: Good for newcomers
- `help wanted`: Extra attention needed
- `security`: Security-related issue
- `performance`: Performance improvements

## 📞 Communication

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Questions and general discussion
- **Discord**: Real-time chat (link in README)
- **Email**: security@siem-plus.io for security issues

## 📜 License

By contributing, you agree that your contributions will be licensed under the Apache 2.0 License.

## 🙏 Recognition

Contributors will be recognized in:
- CHANGELOG.md for each release
- Contributors page on documentation site
- Annual contributor highlights

Thank you for contributing to SIEM-Plus! 🎉
