# 🚀 CI/CD Setup Guide for Ansible

This guide explains how to set up automated syntax and lint checking for your Ansible project across different CI/CD platforms.

## 📋 Overview

Our automation setup provides comprehensive validation including:

- ✅ **Ansible syntax checking** - Validates playbook syntax
- 📝 **YAML linting** - Ensures proper YAML formatting
- 🧹 **Ansible linting** - Checks Ansible best practices
- 📋 **Inventory validation** - Validates inventory structure
- 🔒 **Security scanning** - Detects potential security issues
- 🧪 **Functional testing** - Runs validation playbooks

## 🛠️ Local Development

### Make Commands

Our project uses **Makefile-driven CI/CD** for consistency between local development and CI environments.

```bash
# Install development dependencies
make install-deps

# Prepare CI artifacts (SSH keys for testing)
make prepare-ci-artifacts

# Run all linting checks
make lint

# Run syntax checks only
make syntax

# Run validation tests (with SSH key generation)
make test

# Run full CI pipeline locally
make ci

# Run CI pipeline with automatic cleanup
make ci-clean

# Clean up CI artifacts
make clean-ci-artifacts

# Get help for all targets
make help
```

### Key Benefits of Make-based CI:

- ✅ **Consistency**: Same commands work in CI and locally
- 🔄 **No duplication**: CI workflows call `make` targets, not inline scripts
- 🔑 **SSH key generation**: Automatic SSH key creation for validation tests
- 🧹 **Automatic cleanup**: Restore original configs after testing
- 📊 **Comprehensive**: Combines linting, testing, security, formatting

### Standalone Script

```bash
# Run all checks
./scripts/lint.sh

# Run syntax checks only
./scripts/lint.sh --syntax-only

# Install dependencies and run checks
./scripts/lint.sh --install-deps

# Get help
./scripts/lint.sh --help
```

## 🐙 GitHub Actions

### Setup

1. Your workflow is already configured in `.github/workflows/ansible-ci.yml`
2. Push to `main` or `develop` branches triggers the pipeline
3. Pull requests are automatically validated

### Features

- **Makefile-driven**: All CI steps use `make` targets for consistency
- **Dynamic SSH keys**: Automatic SSH key generation for validation testing
- **Multi-Python testing** (3.9, 3.10, 3.11)
- **Multi-Ansible testing** (6.x, 7.x)
- **Security scanning** with Trivy
- **Artifact collection** for reports and SSH keys
- **PR comments** with results

### CI Workflow Steps

```yaml
# ✅ CENTRALIZED: All dependencies managed by Makefile
- name: Install all dependencies via Makefile
  run: make install-ci-deps
  env:
    ANSIBLE_VERSION: ${{ matrix.ansible-version }} # Pass version to Makefile

# SSH key generation for validation
- name: Prepare CI artifacts (SSH keys)
  run: make prepare-ci-artifacts

# Comprehensive linting (YAML, Ansible, formatting)
- name: Complete Lint & Validation Check
  run: |
    make lint
    make inventory-check

# Functional testing with generated SSH keys
- name: Run functional tests using Makefile
  run: make test

# Security scanning
- name: Run security checks using Makefile
  run: make security-check
```

### Centralized Dependency Management

**Key Principle**: All dependencies are managed exclusively by the Makefile - no duplication in CI workflows.

#### **Makefile Targets**

```bash
# Install all dependencies for CI (with Ansible version support)
ANSIBLE_VERSION=">=7.0.0,<8.0.0" make install-ci-deps

# Install development dependencies
make install-deps

# Complete CI pipeline (includes dependency installation)
make ci
```

#### **Benefits**

- ✅ **Single source of truth**: All dependency logic in Makefile
- ✅ **Version consistency**: CI uses exact same installation as local
- ✅ **No duplication**: Zero redundant dependency management in workflows
- ✅ **Matrix support**: Ansible versions passed via environment variables

### Manual Trigger

```bash
# Via GitHub CLI
gh workflow run "Ansible CI/CD Pipeline"

# Or use the GitHub web interface
```

## 🦊 GitLab CI

### Setup

1. Configuration is in `.gitlab-ci.yml`
2. Automatically triggers on pushes and merge requests
3. Supports GitLab Pages for report hosting

### Features

- **Makefile-driven**: Uses `make` targets consistently (same as GitHub Actions)
- **Multi-stage pipeline** (lint → security → test → report)
- **Parallel execution** for faster builds
- **Artifact collection** and reporting
- **Manual deployment** options
- **GitLab Pages** integration

### CI Pipeline Jobs

```yaml
# Comprehensive linting (replaces individual yaml-lint, ansible-lint, etc.)
comprehensive-lint:
  script: make lint

# Inventory validation
inventory-validation:
  script: make inventory-check

# Security scanning
security-scan:
  script: make security-check

# Functional testing with SSH key generation
functional-test:
  script: make test

# Makefile integration testing
makefile-integration:
  script: |
    make help
    make lint-fix
    make security-check
```

### Manual Trigger

```bash
# Via GitLab CLI
glab pipeline run

# Or trigger specific jobs
glab pipeline run --ref main
```

## 🪝 Pre-commit Hooks

### Setup

```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install

# Run manually on all files
pre-commit run --all-files
```

### Features

- **Automatic validation** on every commit
- **YAML linting** with yamllint
- **Ansible linting** with ansible-lint
- **Security scanning** for secrets
- **File formatting** and cleanup

### Configuration

Edit `.pre-commit-config.yaml` to customize:

```yaml
# Skip specific hooks
SKIP=ansible-lint git commit -m "message"

# Run specific hook only
pre-commit run ansible-lint --all-files
```

## 🔧 Jenkins Pipeline

### Jenkinsfile

```groovy
pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Lint') {
            steps {
                sh 'make lint'
            }
        }

        stage('Test') {
            steps {
                sh 'make test'
            }
        }
    }

    post {
        always {
            publishHTML([
                allowMissing: false,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'reports',
                reportFiles: '*.html',
                reportName: 'Ansible Lint Report'
            ])
        }
    }
}
```

## 🌊 Azure DevOps

### azure-pipelines.yml

```yaml
trigger:
  - main
  - develop

pool:
  vmImage: "ubuntu-latest"

steps:
  - task: UsePythonVersion@0
    inputs:
      versionSpec: "3.10"

  - script: |
      pip install ansible ansible-lint yamllint
    displayName: "Install dependencies"

  - script: |
      make lint
    displayName: "Run lint checks"

  - script: |
      make test
    displayName: "Run tests"

  - publishTestResults:
      testResultsFiles: "**/test-*.xml"
      testRunTitle: "Ansible Tests"
```

## 🚀 Advanced Configuration

### Custom Rules

Create `.ansible-lint-custom` for project-specific rules:

```yaml
# Custom rules for this project
skip_list:
  - yaml[line-length]
  - name[casing]

enable_list:
  - no-changed-when
  - no-handler
```

### Environment Variables

Control behavior with environment variables:

```bash
# Skip certain checks
export ANSIBLE_LINT_SKIP="yaml[line-length],name[casing]"

# Change inventory
export ANSIBLE_INVENTORY="inventories/staging"

# Enable verbose output
export LINT_VERBOSE=1
```

### Docker Integration

```dockerfile
FROM python:3.10-slim

WORKDIR /ansible

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

CMD ["make", "ci"]
```

## 🔍 Troubleshooting

### Common Issues

1. **ansible-lint not found**

   ```bash
   pip install ansible-lint
   # or
   make install-deps
   ```

2. **Inventory validation fails**

   ```bash
   # Check inventory syntax
   ansible-inventory -i inventories/dev --list
   ```

3. **YAML lint errors**
   ```bash
   # Check specific files
   yamllint playbooks/site.yml
   ```

### Debug Mode

```bash
# Enable verbose output
./scripts/lint.sh --verbose

# Or with make
make lint VERBOSE=1
```

## 📊 Metrics and Reporting

### Coverage Reports

The CI generates various reports:

- **Lint reports** - Detailed linting results
- **Security reports** - Vulnerability scanning
- **Test reports** - Functional test results
- **Inventory reports** - Inventory validation

### Integration with Tools

- **SonarQube** - Code quality analysis
- **Snyk** - Security vulnerability scanning
- **Grafana** - CI/CD metrics visualization

## 🔄 Continuous Improvement

### Regular Updates

```bash
# Update pre-commit hooks
pre-commit autoupdate

# Update ansible-lint rules
pip install --upgrade ansible-lint

# Review and update CI configurations quarterly
```

### Best Practices

1. **Keep dependencies updated**
2. **Review and adjust rules** based on project needs
3. **Monitor CI performance** and optimize for speed
4. **Collect metrics** on code quality improvements
5. **Train team** on best practices and tools

## 🆘 Support

- **Documentation**: Check project `docs/` directory
- **Issues**: Create GitHub/GitLab issues for problems
- **Community**: Ansible community forums and Slack
- **Training**: Internal team training on CI/CD practices
