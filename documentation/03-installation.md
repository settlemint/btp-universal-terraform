# Installation Guide

## Installation Methods

BTP Universal Terraform supports multiple installation methods to accommodate different deployment scenarios and user preferences.

## Method 1: Automated Installation Script

### Overview
The automated installation script provides the easiest and most reliable way to deploy BTP Universal Terraform. It handles all the complex setup steps automatically.

### Prerequisites
- Terraform >= 1.0
- kubectl >= 1.28
- Helm >= 3.8
- Cloud provider CLI tools (for cloud deployments)
- Environment variables configured

### Usage

```bash
# Basic usage
bash scripts/install.sh [config-file]

# Examples
bash scripts/install.sh examples/k8s-config.tfvars
bash scripts/install.sh examples/aws-config.tfvars
bash scripts/install.sh examples/azure-config.tfvars
bash scripts/install.sh examples/gcp-config.tfvars
```

### What the Script Does

1. **Environment Validation**
   - Checks for required tools (terraform, kubectl, helm)
   - Validates Kubernetes cluster connectivity
   - Verifies Helm repositories are available

2. **Preflight Checks**
   - Runs comprehensive preflight validation
   - Ensures all prerequisites are met
   - Checks cluster readiness

3. **Terraform Initialization**
   - Downloads required providers
   - Initializes Terraform backend
   - Validates configuration

4. **Registry Authentication**
   - Handles OCI registry login for SettleMint images
   - Manages image pull secrets
   - Downloads charts locally when needed

5. **Staged Deployment**
   - Deploys namespaces first
   - Installs cert-manager CRDs
   - Waits for CRD registration
   - Deploys remaining components

6. **Verification**
   - Checks deployment status
   - Validates component health
   - Provides access URLs

### Script Features

| Feature | Description |
|---------|-------------|
| **Environment Loading** | Automatically loads `.env` files and 1Password references |
| **Registry Management** | Handles OCI registry authentication and chart downloads |
| **Staged Deployment** | Prevents race conditions with proper deployment ordering |
| **Error Handling** | Comprehensive error checking and recovery |
| **Progress Reporting** | Clear status updates throughout the process |

## Method 2: Manual Terraform Installation

### Overview
Manual installation provides full control over the deployment process and is recommended for production environments or when customization is required.

### Step-by-Step Process

#### 1. Environment Setup
```bash
# Load environment variables
source .env

# Verify environment
echo $TF_VAR_postgres_password
echo $BTP_LICENSE_USERNAME
```

#### 2. Preflight Checks
```bash
# Run preflight validation
./scripts/preflight.sh

# Expected output:
# [preflight] Checking kubectl and helm...
# [preflight] Current context: your-cluster-context
# [preflight] Ensuring required Helm repos are present...
# [preflight] OK
```

#### 3. Terraform Initialization
```bash
# Initialize Terraform
terraform init

# Upgrade providers if needed
terraform init -upgrade

# Validate configuration
terraform validate
```

#### 4. Configuration Review
```bash
# Generate deployment plan
terraform plan -var-file examples/k8s-config.tfvars

# Review the plan carefully
# Look for:
# - Resource creation/modification
# - Sensitive data handling
# - Network configuration
# - Security settings
```

#### 5. Staged Deployment

##### Stage 1: Infrastructure Prerequisites
```bash
# Deploy namespaces and cert-manager CRDs first
terraform apply -auto-approve -var-file examples/k8s-config.tfvars \
  -target kubernetes_namespace.deps \
  -target module.ingress_tls.helm_release.cert_manager
```

##### Stage 2: Wait for CRD Registration
```bash
# Wait for cert-manager CRDs to be available
kubectl wait --for=condition=Established crd/clusterissuers.cert-manager.io --timeout=180s
kubectl wait --for=condition=Established crd/issuers.cert-manager.io --timeout=180s
```

##### Stage 3: Full Deployment
```bash
# Deploy all remaining components
terraform apply -auto-approve -var-file examples/k8s-config.tfvars
```

#### 6. Verification
```bash
# Verify deployment
bash scripts/verify.sh

# Check outputs
terraform output
```

## Method 3: CI/CD Pipeline Integration

### Overview
For production environments, integrate BTP Universal Terraform into your CI/CD pipeline for automated, repeatable deployments.

### GitHub Actions Example

```yaml
name: Deploy BTP Universal Terraform

on:
  push:
    branches: [main]
    paths: ['terraform/**', 'examples/**']

env:
  TF_VAR_postgres_password: ${{ secrets.POSTGRES_PASSWORD }}
  TF_VAR_redis_password: ${{ secrets.REDIS_PASSWORD }}
  BTP_LICENSE_USERNAME: ${{ secrets.BTP_LICENSE_USERNAME }}
  BTP_LICENSE_PASSWORD: ${{ secrets.BTP_LICENSE_PASSWORD }}

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: 1.6.0
    
    - name: Setup kubectl
      uses: azure/setup-kubectl@v3
      with:
        version: 'v1.28.0'
    
    - name: Setup Helm
      uses: azure/setup-helm@v3
      with:
        version: 'v3.12.0'
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: eu-central-1
    
    - name: Deploy Infrastructure
      run: |
        bash scripts/install.sh examples/aws-config.tfvars
    
    - name: Verify Deployment
      run: |
        bash scripts/verify.sh
```

### Jenkins Pipeline Example

```groovy
pipeline {
    agent any
    
    environment {
        TF_VAR_postgres_password = credentials('postgres-password')
        TF_VAR_redis_password = credentials('redis-password')
        BTP_LICENSE_USERNAME = credentials('btp-license-username')
        BTP_LICENSE_PASSWORD = credentials('btp-license-password')
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/settlemint/btp-universal-terraform.git'
            }
        }
        
        stage('Setup') {
            steps {
                sh '''
                    terraform --version
                    kubectl version --client
                    helm version
                '''
            }
        }
        
        stage('Deploy') {
            steps {
                sh 'bash scripts/install.sh examples/aws-config.tfvars'
            }
        }
        
        stage('Verify') {
            steps {
                sh 'bash scripts/verify.sh'
            }
        }
    }
    
    post {
        always {
            sh 'terraform output'
        }
    }
}
```

## Installation Validation

### Automated Verification

The verification script performs comprehensive health checks:

```bash
# Run full verification
bash scripts/verify.sh

# Verify specific namespace
bash scripts/verify.sh btp-deps
```

### Manual Verification Steps

#### 1. Check Kubernetes Resources
```bash
# Check all namespaces
kubectl get namespaces

# Check pods in btp-deps namespace
kubectl get pods -n btp-deps

# Check services
kubectl get services -n btp-deps

# Check ingress
kubectl get ingress -n btp-deps
```

#### 2. Verify Helm Releases
```bash
# List all Helm releases
helm list -A

# Check specific release status
helm status ingress -n btp-deps
helm status postgres -n btp-deps
helm status redis -n btp-deps
```

#### 3. Test Service Connectivity
```bash
# Test PostgreSQL connectivity
kubectl run postgres-client --rm -i --tty --image postgres:16-alpine -- \
  psql -h postgres.btp-deps.svc.cluster.local -U postgres -d btp

# Test Redis connectivity
kubectl run redis-client --rm -i --tty --image redis:7-alpine -- \
  redis-cli -h redis-master.btp-deps.svc.cluster.local -a $REDIS_PASSWORD
```

#### 4. Verify TLS Certificates
```bash
# Check cert-manager issuers
kubectl get clusterissuer

# Check certificate status
kubectl get certificate -A

# Verify certificate details
kubectl describe certificate your-domain-tls -n your-namespace
```

## Troubleshooting Installation Issues

### Common Issues

#### Issue: Terraform Provider Download Failed
```bash
# Clear Terraform cache
rm -rf .terraform
rm -rf .terraform.lock.hcl

# Reinitialize
terraform init
```

#### Issue: Helm Chart Download Failed
```bash
# Update Helm repositories
helm repo update

# Check repository status
helm repo list

# Manually add repositories if needed
helm repo add bitnami https://charts.bitnami.com/bitnami
```

#### Issue: Kubernetes Cluster Not Accessible
```bash
# Check kubectl configuration
kubectl config current-context

# Test cluster connectivity
kubectl get nodes

# Check cluster status
kubectl cluster-info
```

#### Issue: OCI Registry Authentication Failed
```bash
# Manual registry login
echo "your_password" | helm registry login harbor.settlemint.com \
  --username "your_username" --password-stdin

# Verify login
helm registry login harbor.settlemint.com --username "your_username"
```

#### Issue: Storage Class Not Available
```bash
# Check available storage classes
kubectl get storageclass

# Create default storage class (Minikube example)
kubectl patch storageclass standard \
  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

### Debug Mode

Enable debug mode for detailed troubleshooting:

```bash
# Enable Terraform debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

# Enable kubectl verbose output
kubectl get pods -v=8

# Enable Helm debug mode
helm install --debug --dry-run your-release chart-name
```

## Post-Installation Configuration

### 1. Access Platform URLs
```bash
# Get deployment outputs
terraform output post_deploy_urls

# Access main platform
open https://your-domain.com

# Access Grafana
open https://grafana.your-domain.com
```

### 2. Configure DNS
```bash
# Get ingress information
kubectl get ingress -A

# Update DNS records to point to ingress IP
# Check ingress controller external IP
kubectl get service -n ingress-nginx
```

### 3. Set Up Monitoring
```bash
# Access Prometheus
open https://prometheus.your-domain.com

# Access Grafana (admin credentials in outputs)
open https://grafana.your-domain.com
```

### 4. Configure Backup
```bash
# Set up database backups (if using managed services)
# Configure object storage backups
# Set up secrets backup strategy
```

## Next Steps

1. **Platform Configuration**: [AWS Deployment Guide](05-aws-deployment.md)
2. **Security Hardening**: [Security Best Practices](19-security.md)
3. **Operations**: [Operations Guide](18-operations.md)
4. **Monitoring**: [Observability Setup](17-observability-module.md)

---

*Choose the installation method that best fits your environment and requirements. For most users, the automated installation script provides the best balance of simplicity and reliability.*
