# Deployment Flow

## Deployment Process Overview

The BTP Universal Terraform deployment follows a structured, multi-stage process designed to ensure reliable and consistent deployments across all supported platforms and deployment modes.

## High-Level Deployment Flow

```mermaid
%%{init: {'theme':'neutral','securityLevel':'loose','flowchart':{'htmlLabels':true,'curve':'basis'}}}%%
graph TD
    START([Start Deployment]) --> PREPARE[Prepare Environment]
    PREPARE --> VALIDATE[Validate Configuration]
    VALIDATE --> INIT[Initialize Terraform]
    INIT --> PLAN[Generate Deployment Plan]
    PLAN --> REVIEW{Review Plan}
    REVIEW -->|Approve| DEPLOY[Deploy Infrastructure]
    REVIEW -->|Reject| PLAN
    DEPLOY --> VERIFY[Verify Deployment]
    VERIFY --> SUCCESS{Deployment Successful?}
    SUCCESS -->|Yes| COMPLETE([Deployment Complete])
    SUCCESS -->|No| TROUBLESHOOT[Troubleshoot Issues]
    TROUBLESHOOT --> DEPLOY
    
    classDef start fill:#E8F5E8,stroke:#388E3C,color:#333
    classDef process fill:#E3F2FD,stroke:#1976D2,color:#333
    classDef decision fill:#FFF8E1,stroke:#F9A825,color:#333
    classDef success fill:#E8F5E8,stroke:#388E3C,color:#333
    classDef error fill:#FFEBEE,stroke:#D32F2F,color:#333
    
    class START,COMPLETE start
    class PREPARE,VALIDATE,INIT,PLAN,DEPLOY,VERIFY process
    class REVIEW,SUCCESS decision
    class TROUBLESHOOT error
```

## Detailed Deployment Stages

### Stage 1: Environment Preparation

```mermaid
%%{init: {'theme':'neutral','securityLevel':'loose','flowchart':{'htmlLabels':true,'curve':'basis'}}}%%
graph TD
    subgraph "Environment Preparation"
        CHECK_TOOLS[Check Required Tools]
        CHECK_CREDS[Verify Credentials]
        LOAD_ENV[Load Environment Variables]
        PREFLIGHT[Run Preflight Checks]
        SETUP_REPOS[Setup Helm Repositories]
        REGISTRY_LOGIN[Login to OCI Registry]
    end
    
    CHECK_TOOLS --> CHECK_CREDS
    CHECK_CREDS --> LOAD_ENV
    LOAD_ENV --> PREFLIGHT
    PREFLIGHT --> SETUP_REPOS
    SETUP_REPOS --> REGISTRY_LOGIN
    
    classDef process fill:#E3F2FD,stroke:#1976D2,color:#333
    class CHECK_TOOLS,CHECK_CREDS,LOAD_ENV,PREFLIGHT,SETUP_REPOS,REGISTRY_LOGIN process
```

#### 1.1 Tool Verification
```bash
# Check required tools
terraform version    # >= 1.0
kubectl version      # >= 1.28
helm version         # >= 3.8

# Verify cloud provider CLI (if applicable)
aws --version        # For AWS deployments
az --version         # For Azure deployments
gcloud --version     # For GCP deployments
```

#### 1.2 Credential Verification
```bash
# Verify Kubernetes access
kubectl cluster-info
kubectl get nodes

# Verify cloud provider access (if applicable)
aws sts get-caller-identity        # AWS
az account show                    # Azure
gcloud auth list                   # GCP
```

#### 1.3 Environment Variables
```bash
# Load environment file
source .env

# Verify required variables
echo $TF_VAR_postgres_password
echo $BTP_LICENSE_USERNAME
echo $BTP_JWT_SIGNING_KEY
```

#### 1.4 Preflight Checks
```bash
# Run comprehensive preflight checks
./scripts/preflight.sh

# Checks include:
# - Tool availability
# - Cluster connectivity
# - Helm repository access
# - OCI registry authentication
# - Storage class availability
```

### Stage 2: Terraform Initialization

```mermaid
%%{init: {'theme':'neutral','securityLevel':'loose','flowchart':{'htmlLabels':true,'curve':'basis'}}}%%
graph TD
    subgraph "Terraform Initialization"
        DOWNLOAD_PROVIDERS[Download Providers]
        DOWNLOAD_MODULES[Download Modules]
        INIT_BACKEND[Initialize Backend]
        VALIDATE_CONFIG[Validate Configuration]
        FORMAT_CODE[Format Code]
    end
    
    DOWNLOAD_PROVIDERS --> DOWNLOAD_MODULES
    DOWNLOAD_MODULES --> INIT_BACKEND
    INIT_BACKEND --> VALIDATE_CONFIG
    VALIDATE_CONFIG --> FORMAT_CODE
    
    classDef process fill:#E3F2FD,stroke:#1976D2,color:#333
    class DOWNLOAD_PROVIDERS,DOWNLOAD_MODULES,INIT_BACKEND,VALIDATE_CONFIG,FORMAT_CODE process
```

#### 2.1 Provider and Module Download
```bash
# Initialize Terraform
terraform init

# Upgrade providers if needed
terraform init -upgrade

# Expected providers:
# - hashicorp/aws
# - hashicorp/azurerm
# - hashicorp/google
# - hashicorp/kubernetes
# - hashicorp/helm
```

#### 2.2 Configuration Validation
```bash
# Validate Terraform configuration
terraform validate

# Format code
terraform fmt -recursive

# Check for security issues (optional)
checkov -d .
```

### Stage 3: Deployment Planning

```mermaid
%%{init: {'theme':'neutral','securityLevel':'loose','flowchart':{'htmlLabels':true,'curve':'basis'}}}%%
graph TD
    subgraph "Deployment Planning"
        GENERATE_PLAN[Generate Deployment Plan]
        REVIEW_RESOURCES[Review Resources]
        CHECK_COSTS[Check Estimated Costs]
        VALIDATE_SECURITY[Validate Security Settings]
        APPROVE_PLAN[Approve Plan]
    end
    
    GENERATE_PLAN --> REVIEW_RESOURCES
    REVIEW_RESOURCES --> CHECK_COSTS
    CHECK_COSTS --> VALIDATE_SECURITY
    VALIDATE_SECURITY --> APPROVE_PLAN
    
    classDef process fill:#E3F2FD,stroke:#1976D2,color:#333
    class GENERATE_PLAN,REVIEW_RESOURCES,CHECK_COSTS,VALIDATE_SECURITY,APPROVE_PLAN process
```

#### 3.1 Plan Generation
```bash
# Generate deployment plan
terraform plan -var-file examples/k8s-config.tfvars

# Save plan to file
terraform plan -var-file examples/k8s-config.tfvars -out deployment.tfplan
```

#### 3.2 Resource Review
```bash
# Review planned resources
terraform show deployment.tfplan

# Check for:
# - Correct resource types
# - Appropriate resource sizes
# - Network configuration
# - Security settings
```

### Stage 4: Staged Deployment

The deployment is executed in stages to prevent race conditions and ensure proper dependency resolution.

```mermaid
%%{init: {'theme':'neutral','securityLevel':'loose','flowchart':{'htmlLabels':true,'curve':'basis'}}}%%
graph TD
    subgraph "Staged Deployment"
        STAGE1[Stage 1: Infrastructure Prerequisites]
        STAGE2[Stage 2: Kubernetes Components]
        STAGE3[Stage 3: Dependencies]
        STAGE4[Stage 4: Platform]
        STAGE5[Stage 5: Verification]
    end
    
    STAGE1 --> STAGE2
    STAGE2 --> STAGE3
    STAGE3 --> STAGE4
    STAGE4 --> STAGE5
    
    classDef stage fill:#E3F2FD,stroke:#1976D2,color:#333
    class STAGE1,STAGE2,STAGE3,STAGE4,STAGE5 stage
```

#### 4.1 Stage 1: Infrastructure Prerequisites
```bash
# Deploy VPC and networking (if applicable)
terraform apply -target module.vpc

# Deploy Kubernetes cluster (if applicable)
terraform apply -target module.k8s_cluster

# Deploy namespaces
terraform apply -target kubernetes_namespace.deps
```

#### 4.2 Stage 2: Kubernetes Components
```bash
# Deploy cert-manager CRDs first
terraform apply -target module.ingress_tls.helm_release.cert_manager

# Wait for CRD registration
kubectl wait --for=condition=Established crd/clusterissuers.cert-manager.io --timeout=180s
kubectl wait --for=condition=Established crd/issuers.cert-manager.io --timeout=180s

# Deploy ingress controller
terraform apply -target module.ingress_tls.helm_release.ingress
```

#### 4.3 Stage 3: Dependencies
```bash
# Deploy database
terraform apply -target module.postgres

# Deploy cache
terraform apply -target module.redis

# Deploy object storage
terraform apply -target module.object_storage

# Deploy secrets management
terraform apply -target module.secrets

# Deploy observability
terraform apply -target module.metrics_logs
```

#### 4.4 Stage 4: Platform
```bash
# Deploy BTP platform
terraform apply -target module.btp
```

#### 4.5 Stage 5: Verification
```bash
# Run verification script
bash scripts/verify.sh

# Check deployment status
kubectl get pods -n btp-deps
kubectl get pods -n settlemint
```

## Deployment Modes

### Automated Deployment (Recommended)

```mermaid
%%{init: {'theme':'neutral','securityLevel':'loose','flowchart':{'htmlLabels':true,'curve':'basis'}}}%%
graph TD
    subgraph "Automated Deployment"
        SCRIPT[Install Script]
        PREFLIGHT_AUTO[Automatic Preflight]
        INIT_AUTO[Automatic Init]
        STAGED_AUTO[Automatic Staged Deploy]
        VERIFY_AUTO[Automatic Verification]
    end
    
    SCRIPT --> PREFLIGHT_AUTO
    PREFLIGHT_AUTO --> INIT_AUTO
    INIT_AUTO --> STAGED_AUTO
    STAGED_AUTO --> VERIFY_AUTO
    
    classDef automated fill:#E8F5E8,stroke:#388E3C,color:#333
    class SCRIPT,PREFLIGHT_AUTO,INIT_AUTO,STAGED_AUTO,VERIFY_AUTO automated
```

```bash
# One-command deployment
bash scripts/install.sh examples/k8s-config.tfvars
```

### Manual Deployment

```mermaid
%%{init: {'theme':'neutral','securityLevel':'loose','flowchart':{'htmlLabels':true,'curve':'basis'}}}%%
graph TD
    subgraph "Manual Deployment"
        PREFLIGHT_MANUAL[Manual Preflight]
        INIT_MANUAL[Manual Init]
        PLAN_MANUAL[Manual Plan]
        REVIEW_MANUAL[Manual Review]
        APPLY_MANUAL[Manual Apply]
        VERIFY_MANUAL[Manual Verify]
    end
    
    PREFLIGHT_MANUAL --> INIT_MANUAL
    INIT_MANUAL --> PLAN_MANUAL
    PLAN_MANUAL --> REVIEW_MANUAL
    REVIEW_MANUAL --> APPLY_MANUAL
    APPLY_MANUAL --> VERIFY_MANUAL
    
    classDef manual fill:#FFF8E1,stroke:#F9A825,color:#333
    class PREFLIGHT_MANUAL,INIT_MANUAL,PLAN_MANUAL,REVIEW_MANUAL,APPLY_MANUAL,VERIFY_MANUAL manual
```

```bash
# Manual step-by-step deployment
./scripts/preflight.sh
terraform init
terraform plan -var-file examples/k8s-config.tfvars
terraform apply -var-file examples/k8s-config.tfvars
bash scripts/verify.sh
```

### CI/CD Deployment

```mermaid
%%{init: {'theme':'neutral','securityLevel':'loose','flowchart':{'htmlLabels':true,'curve':'basis'}}}%%
graph TD
    subgraph "CI/CD Pipeline"
        TRIGGER[Code Commit/PR]
        BUILD[Build Pipeline]
        TEST[Run Tests]
        PLAN_CI[Generate Plan]
        APPROVE_CI[Manual Approval]
        DEPLOY_CI[Deploy to Environment]
        VERIFY_CI[Verify Deployment]
        NOTIFY[Send Notifications]
    end
    
    TRIGGER --> BUILD
    BUILD --> TEST
    TEST --> PLAN_CI
    PLAN_CI --> APPROVE_CI
    APPROVE_CI --> DEPLOY_CI
    DEPLOY_CI --> VERIFY_CI
    VERIFY_CI --> NOTIFY
    
    classDef cicd fill:#F3E5F5,stroke:#7B1FA2,color:#333
    class TRIGGER,BUILD,TEST,PLAN_CI,APPROVE_CI,DEPLOY_CI,VERIFY_CI,NOTIFY cicd
```

## Platform-Specific Deployment Flows

### AWS Deployment Flow

```mermaid
%%{init: {'theme':'neutral','securityLevel':'loose','flowchart':{'htmlLabels':true,'curve':'basis'}}}%%
graph TD
    subgraph "AWS Deployment Flow"
        VPC_AWS[Deploy VPC]
        EKS_AWS[Deploy EKS Cluster]
        RDS_AWS[Deploy RDS PostgreSQL]
        ELASTICACHE_AWS[Deploy ElastiCache Redis]
        S3_AWS[Deploy S3 Bucket]
        COGNITO_AWS[Deploy Cognito User Pool]
        SECRETS_AWS[Deploy Secrets Manager]
        K8S_COMPONENTS_AWS[Deploy K8s Components]
        BTP_AWS[Deploy BTP Platform]
    end
    
    VPC_AWS --> EKS_AWS
    EKS_AWS --> RDS_AWS
    EKS_AWS --> ELASTICACHE_AWS
    EKS_AWS --> S3_AWS
    EKS_AWS --> COGNITO_AWS
    EKS_AWS --> SECRETS_AWS
    EKS_AWS --> K8S_COMPONENTS_AWS
    K8S_COMPONENTS_AWS --> BTP_AWS
    
    classDef aws fill:#FF9900,stroke:#232F3E,color:#fff
    class VPC_AWS,EKS_AWS,RDS_AWS,ELASTICACHE_AWS,S3_AWS,COGNITO_AWS,SECRETS_AWS,K8S_COMPONENTS_AWS,BTP_AWS aws
```

### Azure Deployment Flow

```mermaid
%%{init: {'theme':'neutral','securityLevel':'loose','flowchart':{'htmlLabels':true,'curve':'basis'}}}%%
graph TD
    subgraph "Azure Deployment Flow"
        VNET_AZURE[Deploy Virtual Network]
        AKS_AZURE[Deploy AKS Cluster]
        POSTGRES_AZURE[Deploy Database for PostgreSQL]
        REDIS_AZURE[Deploy Cache for Redis]
        BLOB_AZURE[Deploy Blob Storage]
        ADB2C_AZURE[Deploy AD B2C]
        KEYVAULT_AZURE[Deploy Key Vault]
        K8S_COMPONENTS_AZURE[Deploy K8s Components]
        BTP_AZURE[Deploy BTP Platform]
    end
    
    VNET_AZURE --> AKS_AZURE
    AKS_AZURE --> POSTGRES_AZURE
    AKS_AZURE --> REDIS_AZURE
    AKS_AZURE --> BLOB_AZURE
    AKS_AZURE --> ADB2C_AZURE
    AKS_AZURE --> KEYVAULT_AZURE
    AKS_AZURE --> K8S_COMPONENTS_AZURE
    K8S_COMPONENTS_AZURE --> BTP_AZURE
    
    classDef azure fill:#0078D4,stroke:#005A9E,color:#fff
    class VNET_AZURE,AKS_AZURE,POSTGRES_AZURE,REDIS_AZURE,BLOB_AZURE,ADB2C_AZURE,KEYVAULT_AZURE,K8S_COMPONENTS_AZURE,BTP_AZURE azure
```

### GCP Deployment Flow

```mermaid
%%{init: {'theme':'neutral','securityLevel':'loose','flowchart':{'htmlLabels':true,'curve':'basis'}}}%%
graph TD
    subgraph "GCP Deployment Flow"
        VPC_GCP[Deploy VPC Network]
        GKE_GCP[Deploy GKE Cluster]
        CLOUDSQL_GCP[Deploy Cloud SQL]
        MEMORYSTORE_GCP[Deploy Memorystore Redis]
        GCS_GCP[Deploy Cloud Storage]
        IDENTITY_GCP[Deploy Identity Platform]
        SECRETMANAGER_GCP[Deploy Secret Manager]
        K8S_COMPONENTS_GCP[Deploy K8s Components]
        BTP_GCP[Deploy BTP Platform]
    end
    
    VPC_GCP --> GKE_GCP
    GKE_GCP --> CLOUDSQL_GCP
    GKE_GCP --> MEMORYSTORE_GCP
    GKE_GCP --> GCS_GCP
    GKE_GCP --> IDENTITY_GCP
    GKE_GCP --> SECRETMANAGER_GCP
    GKE_GCP --> K8S_COMPONENTS_GCP
    K8S_COMPONENTS_GCP --> BTP_GCP
    
    classDef gcp fill:#EA4335,stroke:#4285F4,color:#fff
    class VPC_GCP,GKE_GCP,CLOUDSQL_GCP,MEMORYSTORE_GCP,GCS_GCP,IDENTITY_GCP,SECRETMANAGER_GCP,K8S_COMPONENTS_GCP,BTP_GCP gcp
```

### BYO Deployment Flow

```mermaid
%%{init: {'theme':'neutral','securityLevel':'loose','flowchart':{'htmlLabels':true,'curve':'basis'}}}%%
graph TD
    subgraph "BYO Deployment Flow"
        VERIFY_K8S[Verify K8s Cluster]
        VERIFY_DB[Verify Database]
        VERIFY_REDIS[Verify Redis]
        VERIFY_STORAGE[Verify Object Storage]
        VERIFY_IDENTITY[Verify Identity Provider]
        VERIFY_SECRETS[Verify Secrets Management]
        DEPLOY_K8S_COMPONENTS[Deploy K8s Components]
        CONFIGURE_CONNECTIONS[Configure Connections]
        DEPLOY_BTP[Deploy BTP Platform]
    end
    
    VERIFY_K8S --> VERIFY_DB
    VERIFY_DB --> VERIFY_REDIS
    VERIFY_REDIS --> VERIFY_STORAGE
    VERIFY_STORAGE --> VERIFY_IDENTITY
    VERIFY_IDENTITY --> VERIFY_SECRETS
    VERIFY_SECRETS --> DEPLOY_K8S_COMPONENTS
    DEPLOY_K8S_COMPONENTS --> CONFIGURE_CONNECTIONS
    CONFIGURE_CONNECTIONS --> DEPLOY_BTP
    
    classDef byo fill:#666,stroke:#333,color:#fff
    class VERIFY_K8S,VERIFY_DB,VERIFY_REDIS,VERIFY_STORAGE,VERIFY_IDENTITY,VERIFY_SECRETS,DEPLOY_K8S_COMPONENTS,CONFIGURE_CONNECTIONS,DEPLOY_BTP byo
```

## Deployment Validation

### Health Checks

```mermaid
%%{init: {'theme':'neutral','securityLevel':'loose','flowchart':{'htmlLabels':true,'curve':'basis'}}}%%
graph TD
    subgraph "Deployment Validation"
        CHECK_PODS[Check Pod Status]
        CHECK_SERVICES[Check Service Endpoints]
        CHECK_INGRESS[Check Ingress Status]
        CHECK_CERTS[Check Certificate Status]
        CHECK_DB[Check Database Connectivity]
        CHECK_REDIS[Check Redis Connectivity]
        CHECK_STORAGE[Check Storage Connectivity]
        CHECK_AUTH[Check Authentication]
        CHECK_MONITORING[Check Monitoring]
    end
    
    CHECK_PODS --> CHECK_SERVICES
    CHECK_SERVICES --> CHECK_INGRESS
    CHECK_INGRESS --> CHECK_CERTS
    CHECK_CERTS --> CHECK_DB
    CHECK_DB --> CHECK_REDIS
    CHECK_REDIS --> CHECK_STORAGE
    CHECK_STORAGE --> CHECK_AUTH
    CHECK_AUTH --> CHECK_MONITORING
    
    classDef validation fill:#E8F5E8,stroke:#388E3C,color:#333
    class CHECK_PODS,CHECK_SERVICES,CHECK_INGRESS,CHECK_CERTS,CHECK_DB,CHECK_REDIS,CHECK_STORAGE,CHECK_AUTH,CHECK_MONITORING validation
```

### Verification Commands

```bash
# Check pod status
kubectl get pods -n btp-deps
kubectl get pods -n settlemint

# Check service endpoints
kubectl get services -n btp-deps
kubectl get endpoints -n btp-deps

# Check ingress status
kubectl get ingress -n btp-deps
kubectl describe ingress -n btp-deps

# Check certificate status
kubectl get certificate -n btp-deps
kubectl describe certificate -n btp-deps

# Test database connectivity
kubectl run postgres-test --rm -i --tty --image postgres:16-alpine -- \
  psql -h postgres.btp-deps.svc.cluster.local -U postgres -d btp

# Test Redis connectivity
kubectl run redis-test --rm -i --tty --image redis:7-alpine -- \
  redis-cli -h redis-master.btp-deps.svc.cluster.local ping

# Test object storage
kubectl run s3-test --rm -i --tty --image amazon/aws-cli -- \
  aws s3 ls s3://btp-artifacts
```

## Rollback Procedures

### Automated Rollback

```mermaid
%%{init: {'theme':'neutral','securityLevel':'loose','flowchart':{'htmlLabels':true,'curve':'basis'}}}%%
graph TD
    subgraph "Automated Rollback"
        DETECT_FAILURE[Detect Deployment Failure]
        STOP_DEPLOYMENT[Stop Current Deployment]
        RESTORE_PREVIOUS[Restore Previous State]
        VERIFY_ROLLBACK[Verify Rollback]
        NOTIFY_TEAM[Notify Team]
    end
    
    DETECT_FAILURE --> STOP_DEPLOYMENT
    STOP_DEPLOYMENT --> RESTORE_PREVIOUS
    RESTORE_PREVIOUS --> VERIFY_ROLLBACK
    VERIFY_ROLLBACK --> NOTIFY_TEAM
    
    classDef rollback fill:#FFEBEE,stroke:#D32F2F,color:#333
    class DETECT_FAILURE,STOP_DEPLOYMENT,RESTORE_PREVIOUS,VERIFY_ROLLBACK,NOTIFY_TEAM rollback
```

### Manual Rollback

```bash
# Rollback to previous Terraform state
terraform plan -destroy -var-file examples/k8s-config.tfvars
terraform apply -destroy -var-file examples/k8s-config.tfvars

# Rollback specific components
kubectl rollout undo deployment/component-name -n btp-deps

# Rollback Helm releases
helm rollback release-name revision-number -n btp-deps
```

## Best Practices

### 1. **Pre-deployment**
- Always run preflight checks
- Verify credentials and permissions
- Review and approve deployment plans
- Test in non-production environments first

### 2. **During Deployment**
- Use staged deployments for complex environments
- Monitor deployment progress
- Have rollback procedures ready
- Document any custom configurations

### 3. **Post-deployment**
- Run comprehensive verification
- Test all critical functionality
- Update monitoring and alerting
- Document the deployed configuration

### 4. **Security**
- Use least privilege principles
- Encrypt sensitive data
- Enable audit logging
- Regular security updates

### 5. **Monitoring**
- Set up comprehensive monitoring
- Configure alerting for critical issues
- Regular health checks
- Performance monitoring

## Troubleshooting

### Common Issues

#### Issue: Terraform Provider Download Failed
```bash
# Clear cache and retry
rm -rf .terraform
terraform init
```

#### Issue: Kubernetes Cluster Not Accessible
```bash
# Verify cluster access
kubectl cluster-info
kubectl get nodes

# Check kubeconfig
kubectl config current-context
kubectl config get-contexts
```

#### Issue: Helm Chart Download Failed
```bash
# Update Helm repositories
helm repo update

# Check repository status
helm repo list
```

#### Issue: OCI Registry Authentication Failed
```bash
# Manual registry login
echo "password" | helm registry login registry.settlemint.com \
  --username "username" --password-stdin
```

### Debug Mode

```bash
# Enable Terraform debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

# Enable kubectl verbose output
kubectl get pods -v=8

# Enable Helm debug mode
helm install --debug --dry-run release-name chart-name
```

## Next Steps

- [Module Structure](11-module-structure.md) - Understanding module organization
- [Operations Guide](18-operations.md) - Day-to-day operations
- [Troubleshooting Guide](20-troubleshooting.md) - Common issues and solutions

---

*This deployment flow guide provides a comprehensive understanding of the BTP Universal Terraform deployment process. Following these procedures ensures reliable and consistent deployments across all supported platforms.*
