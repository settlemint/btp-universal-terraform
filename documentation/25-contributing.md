# Contributing

## Overview

Thank you for your interest in contributing to the SettleMint BTP Universal Terraform project! This document provides guidelines and information for contributors to help maintain code quality and ensure smooth collaboration.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Contributing Guidelines](#contributing-guidelines)
- [Code Standards](#code-standards)
- [Testing](#testing)
- [Documentation](#documentation)
- [Pull Request Process](#pull-request-process)
- [Release Process](#release-process)
- [Community Guidelines](#community-guidelines)

## Getting Started

### Prerequisites

Before contributing, ensure you have the following tools installed:

- **Terraform**: Version 1.5.0 or higher
- **Kubernetes CLI (kubectl)**: Version 1.28.0 or higher
- **Helm**: Version 3.12.0 or higher
- **Docker**: Version 20.10.0 or higher
- **Git**: Version 2.30.0 or higher
- **Go**: Version 1.21.0 or higher (for testing)
- **Python**: Version 3.9.0 or higher (for testing)

### Installation

```bash
# Install Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

### Fork and Clone

1. **Fork the repository** on GitHub
2. **Clone your fork:**
   ```bash
   git clone https://github.com/your-username/btp-universal-terraform.git
   cd btp-universal-terraform
   ```

3. **Add the upstream remote:**
   ```bash
   git remote add upstream https://github.com/settlemint/btp-universal-terraform.git
   ```

## Development Setup

### Local Development Environment

1. **Set up your development environment:**
   ```bash
   # Create a development branch
   git checkout -b feature/your-feature-name
   
   # Install pre-commit hooks
   pre-commit install
   
   # Install development dependencies
   make install-dev-deps
   ```

2. **Configure your local environment:**
   ```bash
   # Copy example configuration
   cp examples/k8s-config.tfvars dev-config.tfvars
   
   # Edit configuration for your local setup
   vim dev-config.tfvars
   ```

3. **Initialize Terraform:**
   ```bash
   terraform init
   ```

### Testing Environment

1. **Set up a local Kubernetes cluster:**
   ```bash
   # Using kind (Kubernetes in Docker)
   kind create cluster --name btp-dev
   
   # Using minikube
   minikube start
   
   # Using k3d
   k3d cluster create btp-dev
   ```

2. **Configure kubectl:**
   ```bash
   # For kind
   kubectl cluster-info --context kind-btp-dev
   
   # For minikube
   kubectl config use-context minikube
   
   # For k3d
   kubectl config use-context k3d-btp-dev
   ```

3. **Test your changes:**
   ```bash
   # Plan your changes
   terraform plan -var-file=dev-config.tfvars
   
   # Apply your changes
   terraform apply -var-file=dev-config.tfvars
   
   # Verify deployment
   kubectl get pods -A
   ```

## Contributing Guidelines

### Types of Contributions

We welcome the following types of contributions:

- **Bug fixes**: Fix existing issues and bugs
- **New features**: Add new functionality and capabilities
- **Documentation**: Improve or add documentation
- **Tests**: Add or improve test coverage
- **Examples**: Add new configuration examples
- **Performance improvements**: Optimize existing code
- **Security enhancements**: Improve security configurations

### Contribution Process

1. **Check existing issues** to see if your contribution is already being worked on
2. **Create an issue** if you're planning a significant change
3. **Fork the repository** and create a feature branch
4. **Make your changes** following the code standards
5. **Add tests** for your changes
6. **Update documentation** if needed
7. **Submit a pull request** with a clear description

### Issue Guidelines

When creating issues, please:

- **Use descriptive titles** that clearly explain the problem or feature request
- **Provide detailed descriptions** including steps to reproduce for bugs
- **Include relevant information** such as Terraform version, platform, and configuration
- **Add labels** if you have the appropriate permissions
- **Reference related issues** if applicable

**Issue Templates:**

**Bug Report:**
```markdown
## Bug Description
Brief description of the bug

## Steps to Reproduce
1. Step one
2. Step two
3. Step three

## Expected Behavior
What you expected to happen

## Actual Behavior
What actually happened

## Environment
- Terraform version:
- Platform:
- Configuration:
- Kubernetes version:

## Additional Context
Any other context about the problem
```

**Feature Request:**
```markdown
## Feature Description
Brief description of the requested feature

## Use Case
Why is this feature needed?

## Proposed Solution
How should this feature work?

## Alternatives Considered
What other solutions were considered?

## Additional Context
Any other context about the feature request
```

## Code Standards

### Terraform Code Standards

1. **Use consistent formatting:**
   ```bash
   terraform fmt -recursive
   ```

2. **Validate your code:**
   ```bash
   terraform validate
   ```

3. **Follow naming conventions:**
   - Use `snake_case` for variables and outputs
   - Use descriptive names for resources
   - Prefix resources with `btp_` where appropriate

4. **Use proper variable types:**
   ```hcl
   variable "cluster_name" {
     description = "Name of the Kubernetes cluster"
     type        = string
     default     = "btp-cluster"
   }
   
   variable "node_groups" {
     description = "Configuration for node groups"
     type = map(object({
       instance_types = list(string)
       min_size      = number
       max_size      = number
       desired_size  = number
     }))
   }
   ```

5. **Add proper descriptions:**
   ```hcl
   resource "aws_eks_cluster" "btp_cluster" {
     name     = var.cluster_name
     role_arn = aws_iam_role.cluster_role.arn
     version  = var.kubernetes_version
     
     # Add comments for complex configurations
     vpc_config {
       subnet_ids              = var.subnet_ids
       endpoint_private_access = true
       endpoint_public_access  = true
       public_access_cidrs     = var.public_access_cidrs
     }
   }
   ```

### Documentation Standards

1. **Use consistent formatting:**
   - Use Markdown for all documentation
   - Follow the existing documentation structure
   - Use proper heading hierarchy

2. **Include code examples:**
   ```hcl
   # Example configuration
   postgres = {
     mode = "aws"
     aws = {
       cluster_id = "btp-postgres"
       node_type  = "db.t3.medium"
     }
   }
   ```

3. **Add Mermaid diagrams:**
   ```mermaid
   graph TB
     A[User] --> B[Load Balancer]
     B --> C[BTP Platform]
     C --> D[PostgreSQL]
     C --> E[Redis]
   ```

4. **Keep documentation up to date:**
   - Update documentation when making code changes
   - Review documentation in pull requests
   - Remove outdated information

### Git Commit Standards

Use [Conventional Commits](https://www.conventionalcommits.org/) format:

```bash
# Format: <type>[optional scope]: <description>
# Types: feat, fix, docs, style, refactor, test, chore

# Examples:
feat: add support for Azure deployment
fix: resolve PostgreSQL connection issue
docs: update installation guide
style: format Terraform code
refactor: simplify module structure
test: add integration tests for AWS deployment
chore: update dependencies
```

**Commit Message Guidelines:**
- Use the imperative mood ("add feature" not "added feature")
- Keep the first line under 50 characters
- Add more details in the body if needed
- Reference issues with `#123`

## Testing

### Test Structure

```
tests/
├── unit/                 # Unit tests
├── integration/          # Integration tests
├── e2e/                 # End-to-end tests
└── fixtures/            # Test fixtures
```

### Unit Tests

Unit tests are written in Go using the Terraform testing framework:

```go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestPostgreSQLModule(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../deps/postgres",
        Vars: map[string]interface{}{
            "mode": "k8s",
            "namespace": "test",
        },
    }
    
    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)
    
    // Test outputs
    host := terraform.Output(t, terraformOptions, "host")
    assert.NotEmpty(t, host)
}
```

### Integration Tests

Integration tests verify the interaction between modules:

```bash
#!/bin/bash
# tests/integration/test-aws-deployment.sh

set -e

echo "Running AWS deployment integration test"

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file=tests/fixtures/aws-test.tfvars

# Apply deployment
terraform apply -auto-approve -var-file=tests/fixtures/aws-test.tfvars

# Verify deployment
kubectl get pods -A
kubectl get svc -A

# Run health checks
curl -f https://test.btp.example.com/health

# Cleanup
terraform destroy -auto-approve -var-file=tests/fixtures/aws-test.tfvars
```

### End-to-End Tests

E2E tests verify the complete deployment workflow:

```bash
#!/bin/bash
# tests/e2e/test-complete-deployment.sh

set -e

echo "Running complete deployment E2E test"

# Test all platforms
for platform in aws azure gcp generic; do
    echo "Testing $platform deployment"
    
    # Deploy
    terraform apply -auto-approve -var-file=tests/fixtures/${platform}-test.tfvars
    
    # Verify
    ./tests/scripts/verify-deployment.sh $platform
    
    # Cleanup
    terraform destroy -auto-approve -var-file=tests/fixtures/${platform}-test.tfvars
done
```

### Running Tests

```bash
# Run all tests
make test

# Run unit tests
make test-unit

# Run integration tests
make test-integration

# Run E2E tests
make test-e2e

# Run specific test
go test -v ./tests/unit/postgres_test.go
```

## Documentation

### Documentation Structure

```
documentation/
├── 01-overview.md
├── 02-getting-started.md
├── 03-installation.md
├── 04-quick-start-guide.md
├── 05-aws-deployment.md
├── 06-azure-deployment.md
├── 07-gcp-deployment.md
├── 08-bring-your-own-byo.md
├── 09-architecture-overview.md
├── 10-deployment-flow.md
├── 11-module-structure.md
├── 12-postgres-module.md
├── 13-redis-module.md
├── 14-object-storage-module.md
├── 15-oauth-module.md
├── 16-secrets-module.md
├── 17-observability-module.md
├── 18-operations.md
├── 19-security.md
├── 20-troubleshooting.md
├── 21-advanced-configuration.md
├── 22-api-reference.md
├── 23-examples.md
├── 24-faq.md
└── 25-contributing.md
```

### Documentation Guidelines

1. **Keep documentation up to date** with code changes
2. **Use consistent formatting** and structure
3. **Include practical examples** and use cases
4. **Add diagrams** where helpful
5. **Cross-reference** related documentation
6. **Test all examples** before publishing

### Adding New Documentation

1. **Create a new file** in the `documentation/` directory
2. **Follow the naming convention** (number-description.md)
3. **Add to the table of contents** in relevant files
4. **Include proper headings** and structure
5. **Add cross-references** to related documentation

## Pull Request Process

### Before Submitting

1. **Ensure your code follows standards:**
   ```bash
   terraform fmt -recursive
   terraform validate
   make lint
   ```

2. **Run all tests:**
   ```bash
   make test
   ```

3. **Update documentation** if needed

4. **Rebase on latest main:**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

### Pull Request Template

```markdown
## Description
Brief description of the changes

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Security enhancement

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] E2E tests pass
- [ ] Manual testing completed

## Documentation
- [ ] Documentation updated
- [ ] Examples updated
- [ ] API reference updated

## Checklist
- [ ] Code follows project standards
- [ ] Self-review completed
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No breaking changes (or documented)

## Related Issues
Closes #123
```

### Review Process

1. **Automated checks** must pass
2. **Code review** by maintainers
3. **Testing** verification
4. **Documentation** review
5. **Approval** from maintainers

### After Approval

1. **Squash commits** if requested
2. **Merge** by maintainers
3. **Delete feature branch**
4. **Update documentation** if needed

## Release Process

### Versioning

We use [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Release Checklist

1. **Update version** in relevant files
2. **Update changelog** with new features and fixes
3. **Run full test suite**
4. **Create release branch**
5. **Tag release**
6. **Create GitHub release**
7. **Update documentation**

### Release Commands

```bash
# Create release branch
git checkout -b release/v1.2.0

# Update version
vim version.txt

# Update changelog
vim CHANGELOG.md

# Commit changes
git add .
git commit -m "chore: prepare release v1.2.0"

# Tag release
git tag -a v1.2.0 -m "Release v1.2.0"

# Push tags
git push origin v1.2.0

# Create GitHub release
gh release create v1.2.0 --title "Release v1.2.0" --notes-file CHANGELOG.md
```

## Community Guidelines

### Code of Conduct

We follow the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/):

- **Be respectful** and inclusive
- **Be collaborative** and constructive
- **Be patient** with newcomers
- **Be professional** in all interactions

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and discussions
- **Slack**: Real-time communication (invite required)
- **Email**: security@settlemint.com for security issues

### Getting Help

1. **Check documentation** first
2. **Search existing issues** for similar problems
3. **Create a new issue** with detailed information
4. **Join discussions** for general questions
5. **Contact maintainers** for urgent issues

### Recognition

Contributors are recognized in:
- **CONTRIBUTORS.md** file
- **Release notes** for significant contributions
- **GitHub contributors** page
- **Community highlights** in documentation

## Development Workflow

### Daily Workflow

1. **Sync with upstream:**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Create feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make changes** and commit:
   ```bash
   git add .
   git commit -m "feat: add your feature"
   ```

4. **Push and create PR:**
   ```bash
   git push origin feature/your-feature-name
   ```

### Weekly Workflow

1. **Review open issues** and PRs
2. **Update dependencies** if needed
3. **Run full test suite**
4. **Update documentation**
5. **Plan next week's work**

### Monthly Workflow

1. **Review project roadmap**
2. **Update dependencies**
3. **Security audit**
4. **Performance review**
5. **Community feedback review**

## Tools and Resources

### Development Tools

- **Terraform**: Infrastructure as Code
- **Helm**: Kubernetes package manager
- **kubectl**: Kubernetes CLI
- **Docker**: Containerization
- **Go**: Testing framework
- **Python**: Additional testing tools

### Useful Commands

```bash
# Format code
terraform fmt -recursive

# Validate code
terraform validate

# Run tests
make test

# Lint code
make lint

# Build documentation
make docs

# Clean up
make clean
```

### Resources

- [Terraform Documentation](https://www.terraform.io/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [SettleMint Documentation](https://docs.settlemint.com/)

## Next Steps

- [Changelog](26-changelog.md) - Version history
- [Support](27-support.md) - Getting help
- [Community](28-community.md) - Community resources
- [License](LICENSE) - Project license

---

*Thank you for contributing to the SettleMint BTP Universal Terraform project! Your contributions help make this project better for everyone. If you have any questions about contributing, please don't hesitate to ask.*
