# Getting Started with BTP Universal Terraform

## Prerequisites

Before deploying BTP Universal Terraform, ensure you have the following prerequisites in place:

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| **Terraform** | >= 1.0 | Infrastructure provisioning |
| **kubectl** | >= 1.28 | Kubernetes cluster management |
| **Helm** | >= 3.8 | Package management for Kubernetes |
| **Git** | Latest | Repository cloning and version control |

### Cloud Provider CLI Tools (Optional)

| Provider | CLI Tool | Purpose |
|----------|----------|---------|
| **AWS** | AWS CLI | AWS resource management |
| **Azure** | Azure CLI | Azure resource management |
| **GCP** | gcloud CLI | Google Cloud resource management |

### Cloud Provider Accounts

#### AWS Prerequisites
- AWS Account with appropriate permissions
- IAM user or role with required policies
- AWS CLI configured with credentials

#### Azure Prerequisites
- Azure subscription
- Service principal or user with Contributor role
- Azure CLI authenticated

#### GCP Prerequisites
- Google Cloud Project
- Service account with required roles
- gcloud CLI authenticated

### Local Development Environment

#### For Local Kubernetes (OrbStack, Minikube, Kind)
- Local Kubernetes cluster running
- kubectl configured to access the cluster
- Storage class configured for persistent volumes

## Installation Steps

### 1. Clone the Repository

```bash
git clone https://github.com/settlemint/btp-universal-terraform.git
cd btp-universal-terraform
```

### 2. Install Required Tools

#### Terraform Installation
```bash
# macOS (using Homebrew)
brew install terraform

# Linux (using package manager)
sudo apt-get update && sudo apt-get install terraform

# Windows (using Chocolatey)
choco install terraform

# Or download from: https://www.terraform.io/downloads
```

#### kubectl Installation
```bash
# macOS (using Homebrew)
brew install kubectl

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Windows (using Chocolatey)
choco install kubernetes-cli
```

#### Helm Installation
```bash
# macOS (using Homebrew)
brew install helm

# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Windows (using Chocolatey)
choco install kubernetes-helm
```

### 3. Verify Installation

```bash
# Check Terraform version
terraform version

# Check kubectl connection
kubectl version --client

# Check Helm version
helm version

# Verify cluster access (if applicable)
kubectl get nodes
```

### 4. Configure Cloud Provider Access

#### AWS Configuration
```bash
# Configure AWS CLI
aws configure

# Verify access
aws sts get-caller-identity
```

#### Azure Configuration
```bash
# Login to Azure
az login

# Verify access
az account show
```

#### GCP Configuration
```bash
# Login to GCP
gcloud auth login

# Set project
gcloud config set project YOUR_PROJECT_ID

# Verify access
gcloud auth list
```

## Environment Setup

### 1. Create Environment File

Create a `.env` file in the project root for sensitive configuration:

```bash
# Copy example environment file
cp .env.example .env
```

### 2. Configure Required Secrets

Edit the `.env` file with your specific values:

```bash
# SettleMint Platform License
BTP_LICENSE_USERNAME=your_license_username
BTP_LICENSE_PASSWORD=your_license_password
BTP_LICENSE_SIGNATURE=your_license_signature
BTP_LICENSE_EMAIL=your_email@company.com

# Platform Security Secrets
BTP_JWT_SIGNING_KEY=your_64_character_jwt_signing_key
BTP_IPFS_CLUSTER_SECRET=your_64_character_hex_secret
BTP_STATE_ENCRYPTION_KEY=your_base64_encoded_encryption_key

# Dependency Credentials
TF_VAR_postgres_password=your_postgres_password
TF_VAR_redis_password=your_redis_password
TF_VAR_object_storage_access_key=your_minio_access_key
TF_VAR_object_storage_secret_key=your_minio_secret_key
TF_VAR_grafana_admin_password=your_grafana_password
TF_VAR_oauth_admin_password=your_keycloak_password
```

### 3. Generate Secure Secrets

If you need to generate secure secrets, use these commands:

```bash
# Generate JWT signing key (64 characters)
openssl rand -hex 32

# Generate IPFS cluster secret (64 hex characters)
openssl rand -hex 32

# Generate state encryption key (base64)
openssl rand -base64 32

# Generate passwords
openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
```

## Quick Start Options

### Option 1: One-Liner Installation

The fastest way to get started is using the provided installation script:

```bash
# For local Kubernetes development
bash scripts/install.sh examples/k8s-config.tfvars

# For AWS deployment
bash scripts/install.sh examples/aws-config.tfvars

# For Azure deployment
bash scripts/install.sh examples/azure-config.tfvars

# For GCP deployment
bash scripts/install.sh examples/gcp-config.tfvars
```

### Option 2: Manual Installation

For more control over the deployment process:

```bash
# 1. Run preflight checks
./scripts/preflight.sh

# 2. Initialize Terraform
terraform init

# 3. Review the plan
terraform plan -var-file examples/k8s-config.tfvars

# 4. Apply the configuration
terraform apply -var-file examples/k8s-config.tfvars
```

## Configuration Files

### Available Example Configurations

| File | Description | Use Case |
|------|-------------|----------|
| `examples/k8s-config.tfvars` | Kubernetes-native deployment | Development, testing |
| `examples/aws-config.tfvars` | AWS managed services | Production AWS |
| `examples/azure-config.tfvars` | Azure managed services | Production Azure |
| `examples/gcp-config.tfvars` | GCP managed services | Production GCP |
| `examples/byo-config.tfvars` | Bring Your Own infrastructure | Enterprise, existing infrastructure |
| `examples/mixed-config.tfvars` | Mixed deployment modes | Hybrid environments |

### Custom Configuration

Create your own configuration file by copying an example:

```bash
# Copy and customize
cp examples/k8s-config.tfvars my-config.tfvars

# Edit the configuration
vim my-config.tfvars

# Deploy with custom config
terraform apply -var-file my-config.tfvars
```

## Pre-deployment Verification

### 1. Run Preflight Checks

The preflight script verifies your environment:

```bash
./scripts/preflight.sh
```

This script checks:
- ✅ kubectl and Helm are installed
- ✅ Current Kubernetes context
- ✅ Cluster connectivity
- ✅ Required Helm repositories
- ✅ OCI registry login (if credentials provided)
- ✅ Default StorageClass availability

### 2. Validate Configuration

```bash
# Validate Terraform configuration
terraform validate

# Check for syntax errors
terraform fmt -check -recursive
```

### 3. Review Deployment Plan

```bash
# Generate and review the deployment plan
terraform plan -var-file examples/k8s-config.tfvars
```

## Post-deployment Verification

### 1. Check Deployment Status

```bash
# Verify all components are running
bash scripts/verify.sh

# Check specific namespace
bash scripts/verify.sh btp-deps
```

### 2. Access Platform URLs

After successful deployment, you'll get access to:

- **SettleMint Platform**: Main application interface
- **Grafana**: Monitoring and dashboards
- **Prometheus**: Metrics collection
- **Loki**: Log aggregation
- **Keycloak**: Identity management (if enabled)
- **Vault**: Secrets management (if enabled)

### 3. Get Deployment Outputs

```bash
# View all outputs
terraform output

# View specific outputs
terraform output post_deploy_urls
terraform output post_deploy_message
```

## Common Issues and Solutions

### Issue: kubectl connection failed
```bash
# Check current context
kubectl config current-context

# List available contexts
kubectl config get-contexts

# Switch context
kubectl config use-context YOUR_CONTEXT
```

### Issue: Helm repository not found
```bash
# Add required repositories
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

### Issue: StorageClass not found
```bash
# Check available storage classes
kubectl get storageclass

# Create default storage class (example for Minikube)
kubectl patch storageclass standard -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

### Issue: OCI registry authentication failed
```bash
# Manually login to registry
echo "your_password" | helm registry login harbor.settlemint.com --username "your_username" --password-stdin
```

## Next Steps

1. **Choose Your Deployment Target**:
   - [AWS Deployment Guide](05-aws-deployment.md)
   - [Azure Deployment Guide](06-azure-deployment.md)
   - [GCP Deployment Guide](07-gcp-deployment.md)
   - [BYO Deployment Guide](08-bring-your-own-byo.md)

2. **Understand the Architecture**:
   - [Architecture Overview](09-architecture-overview.md)
   - [Deployment Flow](10-deployment-flow.md)

3. **Configure Your Environment**:
   - [Configuration Reference](24-configuration-reference.md)
   - [Security Best Practices](21-security.md)

4. **Deploy and Monitor**:
   - [Operations Guide](18-operations.md)
   - [Troubleshooting Guide](19-troubleshooting.md)

---

*This guide provides the foundation for deploying BTP Universal Terraform. Choose your target platform and follow the specific deployment guide for detailed configuration options.*
