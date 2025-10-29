<p align="center">
  <img src="https://github.com/settlemint/sdk/blob/main/logo.svg" width="200px" align="center" alt="SettleMint logo" />
  <h1 align="center">SettleMint – BTP Universal Terraform</h1>
  <p align="center">
    ✨ <a href="https://settlemint.com">https://settlemint.com</a> ✨
    <br/>
    Standardized, auditable Terraform to provision platform dependencies and deploy SettleMint BTP across clouds.
    <br/>
    Works with AWS, Azure, GCP, and any Kubernetes cluster. Mix managed, Kubernetes (Helm), or bring-your-own backends per dependency.
  </p>
</p>
<br/>

<div align="center">
  <a href="https://console.settlemint.com/documentation/">Documentation</a>
  <span>&nbsp;&nbsp;•&nbsp;&nbsp;</span>
  <a href="https://github.com/settlemint/btp-universal-terraform/issues">Issues</a>
  <span>&nbsp;&nbsp;•&nbsp;&nbsp;</span>
  <a href="./AGENTS.md">Contributor Guide</a>
  <br />
  <a href="./docs/README.md">In-repo docs index</a>
</div>

## Introduction

The SettleMint BTP (Blockchain Technology Platform) Universal Terraform repository provides a standardized, production-ready deployment solution for the SettleMint platform across multiple cloud providers. This repository automates the provisioning of all required infrastructure dependencies and deploys the SettleMint BTP platform using Helm charts.

**What is SettleMint BTP?**
SettleMint BTP is a comprehensive blockchain development platform that provides tools and services for building, deploying, and managing blockchain applications. It includes features like smart contract development, API management, monitoring, and integration capabilities.

**Key Benefits:**
- **One-click deployment** across AWS, Azure, GCP, or any Kubernetes cluster
- **Flexible dependency management** - choose between managed cloud services, Kubernetes-native deployments, or bring-your-own solutions
- **Built-in observability** with Prometheus, Grafana, and Loki
- **Enterprise security** with OAuth integration, secrets management, and TLS encryption
- **Scalable architecture** designed for production workloads

This repository provides a consistent Terraform flow to provision BTP platform dependencies and install the BTP Helm chart. Use the same module to deploy to AWS, Azure, and GCP or any existing Kubernetes cluster. Each dependency can be provided via a managed cloud service, installed inside Kubernetes (Helm), or wired to your own (BYO) endpoints.

For deeper guidance, dive into the in-repo docs starting at [`docs/README.md`](./docs/README.md).

### Key Features

- Unified module layout for dependencies with three modes: k8s (Helm) | managed (cloud) | byo (external)
- Consistent `-var-file` based configuration across environments
- Secrets flow through `TF_VAR_*` inputs, and Terraform marks sensitive outputs automatically
- Observability stack via kube-prometheus-stack and Loki
- Maintained docs under `docs/` covering configuration, operations, and troubleshooting

## Prerequisites

Before starting the deployment, ensure you have the following:

### Required Tools
- **Terraform** (v1.0+) - [Download here](https://www.terraform.io/downloads.html)
- **kubectl** - [Installation guide](https://kubernetes.io/docs/tasks/tools/)
- **Helm** (v3.0+) - [Installation guide](https://helm.sh/docs/intro/install/)
- **Cloud CLI**:
  - **AWS CLI** (v2.0+) - [Installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
  - **gcloud CLI** (for GCP) - [Installation guide](https://cloud.google.com/sdk/docs/install)
  - **Azure CLI** (for Azure) - [Installation guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

### Required Accounts & Services
- **SettleMint License** - Contact SettleMint for platform licensing
- **Cloud Account** - Choose one or more:
  - **AWS Account** - With appropriate permissions for EKS, RDS, ElastiCache, S3, Route53, and Cognito
  - **GCP Account** - With appropriate permissions for GKE, Cloud SQL, Memorystore, Cloud Storage, and Cloud DNS
  - **Azure Account** - With appropriate permissions for AKS, PostgreSQL, Redis, Storage, and DNS
- **Domain Name** - For SSL certificates and platform access (e.g., `yourcompany.com`)

### AWS Permissions Required
Your AWS credentials need permissions for:
- **EKS**: Create/manage clusters, node groups, and IAM roles
- **RDS**: Create/manage PostgreSQL databases
- **ElastiCache**: Create/manage Redis clusters
- **S3**: Create/manage buckets and objects
- **Route53**: Create/manage hosted zones and DNS records
- **Cognito**: Create/manage user pools and clients
- **IAM**: Create/manage roles and policies
- **VPC**: Create/manage VPCs, subnets, and security groups

### GCP Permissions Required
Your GCP account needs permissions for:
- **GKE (Kubernetes Engine)**: Create/manage clusters and node pools
- **Cloud SQL**: Create/manage PostgreSQL instances
- **Memorystore**: Create/manage Redis instances
- **Cloud Storage**: Create/manage buckets and objects
- **Cloud DNS**: Create/manage DNS zones and records (optional)
- **Compute Engine**: Create/manage VPCs, subnets, firewall rules, and Cloud NAT
- **IAM & Service Accounts**: Create/manage service accounts and IAM bindings
- **Service Networking**: Configure private service connections for Cloud SQL

**Required GCP APIs** (enable these in your project):
```bash
gcloud services enable container.googleapis.com         # GKE
gcloud services enable compute.googleapis.com           # Compute/VPC
gcloud services enable sqladmin.googleapis.com          # Cloud SQL
gcloud services enable redis.googleapis.com             # Memorystore Redis
gcloud services enable storage.googleapis.com           # Cloud Storage
gcloud services enable dns.googleapis.com               # Cloud DNS
gcloud services enable servicenetworking.googleapis.com # Private networking
```

## Step-by-Step Deployment Guide

This repository supports deployment to **AWS**, **GCP**, and **Azure**. Choose your target platform:

### AWS Deployment

Follow these steps to deploy SettleMint BTP on AWS:

### Step 1: Get SettleMint License

Contact SettleMint to obtain your platform license. You'll receive the following parameters:

- **License Username** (`TF_VAR_license_username`) - Your license username
- **License Password** (`TF_VAR_license_password`) - Your license password
- **License Signature** (`TF_VAR_license_signature`) - Cryptographic signature for license validation
- **License Email** (`TF_VAR_license_email`) - Email associated with the license
- **License Expiration Date** (`TF_VAR_license_expiration_date`) - License validity period (format: YYYY-MM-DD)

**Note**: These parameters will be used in Step 4 when configuring your environment variables.

### Step 2: Set Up AWS Credentials

#### Option A: AWS CLI Configuration (Recommended)
```bash
# Configure AWS CLI with your credentials
aws configure
# Enter your Access Key ID, Secret Access Key, and preferred region
```

#### Option B: IAM User Setup
1. **Log into AWS Console** → Go to IAM service
2. **Create IAM User**:
   - Click "Users" → "Create user"
   - Username: `btp-terraform-user` (or your preferred name)
   - Select "Programmatic access"
3. **Attach Policies**:
   - `AmazonEKSClusterPolicy`
   - `AmazonEKSWorkerNodePolicy`
   - `AmazonEKS_CNI_Policy`
   - `AmazonRDSFullAccess`
   - `AmazonElastiCacheFullAccess`
   - `AmazonS3FullAccess`
   - `AmazonRoute53FullAccess`
   - `AmazonCognitoPowerUser`
   - `IAMFullAccess`
   - `AmazonVPCFullAccess`
4. **Create Access Keys**:
   - Go to "Security credentials" tab
   - Click "Create access key"
   - Choose "Application running outside AWS"
   - **Save the Access Key ID and Secret Access Key** - you'll need these in Step 4

### Step 3: Set Up DNS with Route53

#### Create Hosted Zone
1. **Log into AWS Console** → Go to Route53 service
2. **Create Hosted Zone**:
   - Click "Hosted zones" → "Create hosted zone"
   - Domain name: `yourdomain.com` (replace with your actual domain)
   - Type: "Public hosted zone"
   - Click "Create hosted zone"

#### Update Domain Nameservers
1. **Copy Nameservers** from the created hosted zone (4 NS records)
2. **Update Domain Registrar**:
   - Log into your domain registrar (GoDaddy, Namecheap, etc.)
   - Go to DNS management for your domain
   - Replace existing nameservers with the Route53 nameservers
   - **Wait 24-48 hours** for DNS propagation

#### Verify DNS Setup
```bash
# Check if nameservers are updated
dig NS yourdomain.com
# Should show Route53 nameservers
```

### Step 4: Configure Your Deployment

#### Copy and Edit Configuration Files
```bash
# Clone the repository
git clone https://github.com/settlemint/btp-universal-terraform.git
cd btp-universal-terraform

# Copy the AWS example configuration
cp examples/aws-config.tfvars aws-config.tfvars

# Copy the environment template
cp .env.example .env
```

#### Edit `aws-config.tfvars`
Update the following parameters in your configuration file:

**Required Changes:**
```hcl
# Update domain (replace with your actual domain)
base_domain = "yourdomain.com"

# Update VPC and cluster names (replace 'yourname' with your identifier)
vpc = {
  aws = {
    vpc_name = "btp-vpc-yourname"
    region   = "eu-central-1"  # Change to your preferred AWS region
  }
}

k8s_cluster = {
  aws = {
    cluster_name = "btp-eks-yourname"
    region       = "us-east-1"  # Must match VPC region
  }
}

# Update DNS configuration
dns = {
  domain = "yourdomain.com"  # Must match your actual domain
  aws = {
    zone_name = "yourdomain.com"  # Must match your Route53 hosted zone
  }
}

# Update OAuth callback URL
oauth = {
  aws = {
    domain_prefix = "btp-yourname-platform"  # Must be globally unique
    callback_urls = ["https://yourdomain.com/api/auth/callback/cognito"]
  }
}
```

**Optional Changes:**
- **Region**: Change `eu-central-1` to your preferred AWS region
- **Instance Types**: Modify `t3.medium` to `t3.large` or `t3.xlarge` for higher performance
- **Node Count**: Adjust `desired_size`, `min_size`, `max_size` based on your needs
- **Database Size**: Change `db.t3.small` to larger instance for production

#### Edit `.env` File
Fill in all the required environment variables:

```bash
# AWS Credentials (from Step 2)
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
AWS_REGION=us-east-1

# SettleMint License (from Step 1)
TF_VAR_license_username=your-license-username
TF_VAR_license_password=your-license-password
TF_VAR_license_signature=your-license-signature
TF_VAR_license_email=your-email@example.com
TF_VAR_license_expiration_date=2025-12-31

# Database Passwords (generate strong passwords)
TF_VAR_postgres_password=your-strong-postgres-password
TF_VAR_redis_password=your-strong-redis-password

# Object Storage Credentials (generate unique keys)
TF_VAR_object_storage_access_key=your-access-key
TF_VAR_object_storage_secret_key=your-secret-key

# Platform Secrets (generate strong, unique values)
TF_VAR_grafana_admin_password=your-grafana-password
TF_VAR_oauth_admin_password=your-oauth-password
TF_VAR_jwt_signing_key=your-jwt-signing-key
TF_VAR_ipfs_cluster_secret=your-64-char-hex-string
TF_VAR_state_encryption_key=your-state-encryption-key

# AWS Credentials for deployment engine
TF_VAR_aws_access_key_id=AKIA...  # Same as AWS_ACCESS_KEY_ID
TF_VAR_aws_secret_access_key=...  # Same as AWS_SECRET_ACCESS_KEY
```

### Step 5: Deploy the Platform

#### Initialize and Deploy
```bash
# Load environment variables
set -a && source .env && set +a

# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan -var-file examples/aws-config.tfvars

# Deploy the platform (takes 15-20 minutes)
terraform apply -var-file examples/aws-config.tfvars
```

#### Monitor Deployment
The deployment will create:
- VPC with public/private subnets
- EKS cluster with worker nodes
- RDS PostgreSQL database
- ElastiCache Redis cluster
- S3 bucket for object storage
- Route53 DNS records
- Cognito user pool
- SettleMint BTP platform

### Step 6: Create Platform User

After successful deployment, create a user in AWS Cognito:

1. **Log into AWS Console** → Go to Cognito service
2. **Find Your User Pool**:
   - Look for pool named `btp-users` (or as configured)
   - Click on the pool name
3. **Create User**:
   - Click "Users" tab → "Create user"
   - Username: `admin` (or your preferred username)
   - Email: `admin@yourdomain.com`
   - Password: Create a strong password
   - **Uncheck "Mark email as verified"** (you'll verify manually)
4. **Verify Email**:
   - Click on the created user
   - Click "Actions" → "Confirm user"
   - Confirm the email verification

### Step 7: Access Your Platform

After deployment completes, you'll see output similar to:

```
post_deploy_urls = {
  platform_url = "https://yourdomain.com"
  grafana_url  = "http://kps-grafana.btp-deps.svc.cluster.local"
  # ... other endpoints
}
```

**Access Points:**
- **SettleMint Platform**: `https://yourdomain.com`
- **Grafana Monitoring**: Use kubectl port-forward or ingress
- **Database**: Connection details in Terraform output
- **Object Storage**: S3 bucket details in Terraform output

**Login Credentials:**
- Use the Cognito user created in Step 6
- Platform URL: `https://yourdomain.com`

---

### GCP Deployment

Follow these steps to deploy SettleMint BTP on Google Cloud Platform:

#### Step 1: Get SettleMint License

Same as AWS - Contact SettleMint to obtain your platform license parameters.

#### Step 2: Set Up GCP Project

**Create or Select a GCP Project:**
```bash
# List existing projects
gcloud projects list

# Create a new project (optional)
gcloud projects create YOUR_PROJECT_ID --name="BTP Platform"

# Set the active project
gcloud config set project YOUR_PROJECT_ID

# Enable billing for the project (required)
# Go to: https://console.cloud.google.com/billing
```

**Install gcloud CLI:**
- Download from: https://cloud.google.com/sdk/docs/install
- Or use package manager:
  ```bash
  # macOS
  brew install google-cloud-sdk

  # Linux (Ubuntu/Debian)
  sudo apt-get install google-cloud-sdk
  ```

#### Step 3: Authenticate with GCP

```bash
# Authenticate your user account
gcloud auth login

# Set up application default credentials for Terraform
gcloud auth application-default login

# Verify authentication
gcloud auth list
```

#### Step 4: Enable Required GCP APIs

```bash
# Enable all required APIs
gcloud services enable container.googleapis.com         # GKE
gcloud services enable compute.googleapis.com           # Compute/VPC
gcloud services enable sqladmin.googleapis.com          # Cloud SQL
gcloud services enable redis.googleapis.com             # Memorystore Redis
gcloud services enable storage.googleapis.com           # Cloud Storage
gcloud services enable dns.googleapis.com               # Cloud DNS (optional)
gcloud services enable servicenetworking.googleapis.com # Private networking

# Verify APIs are enabled
gcloud services list --enabled
```

#### Step 5: Set Up DNS with Cloud DNS (Optional)

**Create a DNS Managed Zone:**
```bash
# Create managed zone
gcloud dns managed-zones create btp-zone \
  --dns-name="yourdomain.com." \
  --description="BTP Platform DNS Zone"

# Get nameservers
gcloud dns managed-zones describe btp-zone --format="value(nameServers)"
```

**Update Domain Registrar:**
1. Copy the Cloud DNS nameservers from the output above
2. Log into your domain registrar (GoDaddy, Namecheap, etc.)
3. Update your domain's nameservers to use the Cloud DNS nameservers
4. Wait 24-48 hours for DNS propagation

**Verify DNS Setup:**
```bash
# Check if nameservers are updated
dig NS yourdomain.com
```

#### Step 6: Configure Your Deployment

**Clone the repository and create configuration:**
```bash
# Copy the example configuration
cp examples/gcp-config.tfvars my-gcp-deployment.tfvars

# Edit the configuration file
# Update the following in my-gcp-deployment.tfvars:
# - All instances of "my-gcp-project" with YOUR_PROJECT_ID
# - base_domain with your actual domain
# - region with your preferred GCP region (e.g., us-central1, europe-west1)
```

**Key GCP-specific settings to configure:**
```hcl
platform = "gcp"
base_domain = "yourdomain.com"

k8s_cluster = {
  mode = "gcp"
  gcp = {
    project_id         = "YOUR_PROJECT_ID"
    cluster_name       = "btp-cluster"
    region             = "us-central1"
    kubernetes_version = "1.31"

    node_pools = {
      default = {
        machine_type   = "e2-standard-4"  # 4 vCPU, 16GB RAM
        min_node_count = 1
        max_node_count = 10
        auto_scaling   = true
      }
    }
  }
}

postgres = {
  mode = "gcp"
  gcp = {
    project_id       = "YOUR_PROJECT_ID"
    instance_name    = "btp-postgres"
    tier             = "db-custom-2-7680" # 2 vCPU, 7.5GB RAM
    availability_type = "REGIONAL"        # High availability
  }
}

redis = {
  mode = "gcp"
  gcp = {
    project_id     = "YOUR_PROJECT_ID"
    instance_name  = "btp-redis"
    tier           = "STANDARD_HA" # High availability
    memory_size_gb = 5
  }
}

object_storage = {
  mode = "gcp"
  gcp = {
    project_id  = "YOUR_PROJECT_ID"
    location    = "US" # Multi-region
  }
}
```

#### Step 7: Set Environment Variables

**Create `.env` file:**
```bash
# Copy the example
cp .env.example .env

# Edit .env and set these required variables:
TF_VAR_postgres_password="your-secure-password-min-8-chars"
TF_VAR_redis_password="your-secure-password-min-16-chars"
TF_VAR_grafana_admin_password="your-secure-password-min-12-chars"
TF_VAR_oauth_admin_password="your-secure-password-min-16-chars"

# Platform secrets (generate random strings)
TF_VAR_jwt_signing_key="random-32-character-string-here"
TF_VAR_state_encryption_key="random-32-character-string-here"
TF_VAR_ipfs_cluster_secret="64-character-hexadecimal-string"

# License credentials from Step 1
TF_VAR_license_username="your-license-username"
TF_VAR_license_password="your-license-password"
TF_VAR_license_signature="your-license-signature"
TF_VAR_license_email="your-email@example.com"
TF_VAR_license_expiration_date="2025-12-31"
```

**Load environment variables:**
```bash
set -a
source .env
set +a
```

#### Step 8: Initialize Terraform

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Review the deployment plan
terraform plan -var-file=my-gcp-deployment.tfvars
```

#### Step 9: Deploy Infrastructure

```bash
# Apply the configuration
terraform apply -var-file=my-gcp-deployment.tfvars

# Type 'yes' when prompted to confirm
```

**Expected deployment time:** ~20-25 minutes
- GKE cluster creation: ~10 minutes
- Cloud SQL instance: ~8 minutes
- Memorystore Redis: ~5 minutes
- Kubernetes workloads: ~5 minutes

#### Step 10: Configure kubectl

```bash
# Get GKE credentials
gcloud container clusters get-credentials btp-cluster \
  --region=us-central1 \
  --project=YOUR_PROJECT_ID

# Verify connection
kubectl get nodes
kubectl get namespaces
```

#### Step 11: Verify Deployment

**Check infrastructure status:**
```bash
# View Terraform outputs
terraform output

# Check GKE cluster
gcloud container clusters describe btp-cluster --region=us-central1

# Check Cloud SQL
gcloud sql instances describe btp-postgres

# Check Memorystore Redis
gcloud redis instances describe btp-redis --region=us-central1

# Check all pods are running
kubectl get pods -A
```

**Get access URLs:**
```bash
# Get Grafana URL (monitoring)
kubectl get ingress -n btp-deps grafana-ingress

# Get platform URL
kubectl get ingress -n settlemint
```

#### Step 12: Access the Platform

Once DNS has propagated (if configured), access your platform:
- **Platform URL**: `https://yourdomain.com`
- **Grafana**: `https://grafana.yourdomain.com`

**Initial Setup:**
1. Access the platform URL in your browser
2. Complete the Google OAuth setup (see GCP Console > APIs & Services > Credentials)
3. Create your first administrator user
4. Start deploying blockchain networks!

### GCP Testing Guide

For a minimal test deployment (without production workloads), see the [GCP Testing Guide](./GCP_TESTING_GUIDE.md) which includes:
- Automated testing script (`./test-gcp.sh`)
- Minimal configuration example (`test-gcp.tfvars`)
- Cost estimates for testing (~$120-200/month)
- Step-by-step troubleshooting

## Troubleshooting

### Common Issues and Solutions

#### DNS Issues
**Problem**: Platform not accessible via domain name
**Solutions**:
```bash
# Check DNS propagation
dig yourdomain.com
nslookup yourdomain.com

# Verify Route53 nameservers
dig NS yourdomain.com

# Check if nameservers are correctly set at domain registrar
```

#### AWS Permissions Errors
**Problem**: `AccessDenied` errors during deployment
**Solutions**:
- Verify IAM user has all required policies attached
- Check if AWS credentials are correctly configured: `aws sts get-caller-identity`
- Ensure region matches between credentials and configuration

#### Terraform State Issues
**Problem**: State file conflicts or corruption
**Solutions**:
```bash
# Refresh state
terraform refresh -var-file aws-config.tfvars

# Import existing resources if needed
terraform import aws_instance.example i-1234567890abcdef0

# Backup state before major changes
cp terraform.tfstate terraform.tfstate.backup
```

#### EKS Cluster Issues
**Problem**: Cluster not accessible or nodes not joining
**Solutions**:
```bash
# Check cluster status
aws eks describe-cluster --name btp-eks-yourname --region us-east-1

# Verify kubectl context
kubectl config current-context

# Check node status
kubectl get nodes
```

#### Certificate Issues
**Problem**: SSL certificates not issued or invalid
**Solutions**:
```bash
# Check cert-manager logs
kubectl logs -n btp-deps -l app=cert-manager

# Verify ClusterIssuer
kubectl get clusterissuer

# Check certificate status
kubectl get certificate -n btp-deps
```

#### Platform Not Starting
**Problem**: SettleMint platform pods not running
**Solutions**:
```bash
# Check pod status
kubectl get pods -n settlemint

# Check logs
kubectl logs -n settlemint -l app=settlemint-platform

# Verify all dependencies are running
kubectl get pods -n btp-deps
```

### Getting Help

1. **Check Logs**: Use `kubectl logs` to examine pod logs
2. **Verify Resources**: Use `kubectl get all` to check resource status
3. **AWS Console**: Check AWS services directly in the console
4. **Documentation**: Refer to `docs/` directory for detailed guides
5. **Issues**: Report bugs at [GitHub Issues](https://github.com/settlemint/btp-universal-terraform/issues)

### Cleanup

To remove all resources:
```bash
# Destroy all infrastructure
terraform destroy -var-file examples/aws-config.tfvars

# Clean up local files
rm -f .env examples/aws-config.tfvars
```

## Quick Start (Alternative)

Choose the configuration that matches your deployment target (inherit and edit as needed):

- **`examples/k8s-config.tfvars`** – Kubernetes-native (Helm charts for all dependencies)
- **`examples/aws-config.tfvars`** – AWS managed services plus ingress DNS automation
- **`examples/azure-config.tfvars`** – Azure bring-your-own endpoints (managed modules landing soon)
- **`examples/gcp-config.tfvars`** – GCP bring-your-own endpoints (managed modules landing soon)
- **`examples/mixed-config.tfvars`** – Sample blend of managed + k8s + byo modes
- **`examples/byo-config.tfvars`** – Fully external dependencies

See `docs/configuration.md` for the inputs you typically override and how to supply secrets.

### Apply Workflow

```bash
# Initialize Terraform
terraform init

# Review plan and apply using your config
terraform plan  -var-file examples/aws-config.tfvars
terraform apply -var-file examples/aws-config.tfvars

# Tear down when finished
terraform destroy -var-file examples/aws-config.tfvars
```

Need more guidance? Follow `docs/getting-started.md` for prerequisites and verification steps.

To deploy the SettleMint platform itself, enable the `/btp` module in your tfvars (see the `btp` block in `variables.tf`) and follow the notes in `docs/configuration.md`.

### Managing secrets with environment variables

Terraform requires sensitive credentials (passwords, API keys, license details) to provision dependencies. Supply these via environment variables—never commit them to version control.

**Quick start:**

```bash
# Copy the example and fill in your values
cp .env.example .env

# Load variables and apply
set -a && source .env && set +a
terraform apply -var-file examples/aws-config.tfvars
```

The `.env.example` file lists all required variables with the `TF_VAR_` prefix that Terraform reads automatically.

**Using a password manager:**

Integrate with 1Password, AWS Secrets Manager, HashiCorp Vault, or other tools to inject secrets at runtime. See `docs/configuration.md` for detailed examples of each method.

For a complete guide on environment variable handling, credential requirements, and password manager integration, refer to the "Secrets and credentials" section in `docs/configuration.md`.

## Typical development workflow

- Edit module code under `./deps/*` or root variables/outputs.
- Format and validate:

```bash
terraform fmt -recursive
terraform validate
terraform plan -var-file examples/aws-config.tfvars
terraform apply -var-file examples/aws-config.tfvars
```

- Destroy when finished:

```bash
terraform destroy -var-file examples/aws-config.tfvars
```

### Smoke checks

- Ingress controller ready; cert-manager `ClusterIssuer` exists
- Postgres/Redis services resolvable in-cluster; MinIO UI/API reachable
- Grafana accessible; Prometheus up; Loki receiving logs
- Keycloak admin reachable; Vault server responding (dev mode)

See `docs/operations.md` for additional day-2 tasks and verification tips.

- Dependencies deploy to `btp-deps` by default (override per dependency via `var.<dep>.k8s.namespace` or `var.namespaces`).
- The BTP chart deploys to `btp` by default (configurable in `btp` module).

See `docs/architecture.md` for an overview diagram showing how modules connect.

## Architecture Overview

- Root module wires dependency modules and normalizes outputs.
- Modules:
  - `./deps/{postgres,redis,object_storage,oauth,secrets,ingress_tls,metrics_logs}` implement managed/k8s/byo modes.
  - `./btp` module maps normalized outputs to BTP chart values.
- Examples live in `./examples/*.tfvars`.

## Quality Assurance

```bash
terraform fmt -recursive      # formatting
terraform validate            # static validation
tflint --init && tflint       # lint (if TFLint is installed)
checkov -d .                  # optional security scan (if installed)
```

Before PRs: include plan output for the relevant tfvars and note any input/output changes. See `AGENTS.md` for conventions.

## Backends & State

For local development, the default local state is fine. For shared environments, configure a remote backend (e.g., S3, GCS, AzureRM). Example (commented):

```hcl
# terraform {
#   backend "s3" {
#     bucket = "my-tf-state"
#     key    = "btp-universal-terraform/terraform.tfstate"
#     region = "us-east-1"
#   }
# }
```
