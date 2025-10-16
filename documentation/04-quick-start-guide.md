# Quick Start Guide

## 5-Minute Deployment

This guide will get you up and running with BTP Universal Terraform in under 5 minutes using a local Kubernetes cluster.

## Prerequisites Check

Before starting, ensure you have:

```bash
# Check required tools
terraform version    # Should be >= 1.0
kubectl version      # Should be >= 1.28
helm version         # Should be >= 3.8

# Verify Kubernetes cluster
kubectl get nodes    # Should show your cluster nodes
```

## Step 1: Clone and Setup

```bash
# Clone the repository
git clone https://github.com/settlemint/btp-universal-terraform.git
cd btp-universal-terraform

# Create environment file
cp .env.example .env
```

## Step 2: Configure Environment

Edit the `.env` file with your values:

```bash
# Minimum required configuration
TF_VAR_postgres_password="SecurePostgresPassword123!"
TF_VAR_redis_password="SecureRedisPassword123456789"
TF_VAR_object_storage_access_key="minioadmin"
TF_VAR_object_storage_secret_key="minioadmin123456789012"
TF_VAR_grafana_admin_password="SecureGrafanaPassword123"
TF_VAR_oauth_admin_password="SecureKeycloakPassword123456"

# Platform secrets (generate with: openssl rand -hex 32)
BTP_JWT_SIGNING_KEY="your_64_character_jwt_signing_key_here_replace_with_real_value"
BTP_IPFS_CLUSTER_SECRET="your_64_character_hex_secret_here_replace_with_real_value"
BTP_STATE_ENCRYPTION_KEY="your_base64_encoded_encryption_key_here_replace_with_real"

# License (if you have one)
BTP_LICENSE_USERNAME="your_license_username"
BTP_LICENSE_PASSWORD="your_license_password"
```

## Step 3: Deploy

```bash
# One-command deployment
bash scripts/install.sh examples/k8s-config.tfvars
```

This will:
- ✅ Run preflight checks
- ✅ Initialize Terraform
- ✅ Deploy all components
- ✅ Verify deployment

## Step 4: Access Your Platform

After successful deployment, you'll see output like:

```
Apply complete. Selected outputs (sensitive values hidden):

post_deploy_urls = {
  "grafana_url" = "https://grafana.127.0.0.1.nip.io"
  "grafana_username" = "admin"
  "platform_url" = "https://127.0.0.1.nip.io"
  "redis_endpoint" = "redis-master.btp-deps.svc.cluster.local:6379 (tls=false)"
}
```

Access your services:

```bash
# Open platform in browser
open https://127.0.0.1.nip.io

# Access Grafana (admin/SecureGrafanaPassword123)
open https://grafana.127.0.0.1.nip.io
```

## What You've Deployed

Your deployment includes:

| Component | Purpose | Access URL |
|-----------|---------|------------|
| **SettleMint Platform** | Main blockchain platform | `https://127.0.0.1.nip.io` |
| **PostgreSQL** | Database | Internal cluster service |
| **Redis** | Cache and session store | Internal cluster service |
| **MinIO** | Object storage | Internal cluster service |
| **Grafana** | Monitoring dashboards | `https://grafana.127.0.0.1.nip.io` |
| **Prometheus** | Metrics collection | Internal cluster service |
| **Loki** | Log aggregation | Internal cluster service |
| **nginx Ingress** | Load balancer and TLS | External IP |
| **cert-manager** | TLS certificate management | Internal service |

## Verify Deployment

```bash
# Run verification script
bash scripts/verify.sh

# Check pod status
kubectl get pods -n btp-deps

# Check services
kubectl get services -n btp-deps
```

Expected output:
```
[OK]  helm release 'ingress' is deployed
[OK]  deployment ready: selector 'app.kubernetes.io/instance=ingress,app.kubernetes.io/name=ingress-nginx'
[OK]  helm release 'postgres' is deployed
[OK]  Postgres SELECT 1 succeeded
[OK]  Redis PING succeeded
[OK]  MinIO bucket create/delete succeeded
```

## Next Steps

### 1. Explore the Platform
- Access the SettleMint Platform at your URL
- Create your first blockchain network
- Explore the monitoring dashboards in Grafana

### 2. Customize Configuration
```bash
# Copy and modify configuration
cp examples/k8s-config.tfvars my-config.tfvars

# Edit configuration
vim my-config.tfvars

# Apply changes
terraform apply -var-file my-config.tfvars
```

### 3. Scale Your Deployment
```bash
# Check current resource usage
kubectl top nodes
kubectl top pods -n btp-deps

# Scale components if needed
kubectl scale deployment your-deployment --replicas=3 -n btp-deps
```

## Common Quick Start Issues

### Issue: Port Forwarding Required
If you can't access the platform via the nip.io URL:

```bash
# Get the ingress controller external IP
kubectl get service -n ingress-nginx

# If using NodePort, forward ports manually
kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80
kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8443:443

# Access via localhost
open http://localhost:8080
```

### Issue: Storage Class Not Found
```bash
# Check available storage classes
kubectl get storageclass

# For Minikube, create default storage class
kubectl patch storageclass standard \
  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

### Issue: Certificate Not Ready
```bash
# Check certificate status
kubectl get certificate -A

# Check cert-manager logs
kubectl logs -n btp-deps deployment/cert-manager
```

## Clean Up

To remove the deployment:

```bash
# Destroy all resources
terraform destroy -var-file examples/k8s-config.tfvars

# Or use the cleanup script
bash scripts/destroy.sh examples/k8s-config.tfvars
```

## Production Considerations

This quick start uses development-friendly defaults:

- ⚠️ **No persistence**: Data will be lost on pod restart
- ⚠️ **Self-signed certificates**: Not suitable for production
- ⚠️ **Default passwords**: Change all passwords for production
- ⚠️ **No backup strategy**: Implement backups for production

For production deployment, see:
- [AWS Deployment Guide](05-aws-deployment.md)
- [Azure Deployment Guide](06-azure-deployment.md)
- [GCP Deployment Guide](07-gcp-deployment.md)

## Platform-Specific Quick Starts

### AWS Quick Start
```bash
# Prerequisites: AWS CLI configured
aws sts get-caller-identity

# Deploy to AWS
bash scripts/install.sh examples/aws-config.tfvars
```

### Azure Quick Start
```bash
# Prerequisites: Azure CLI configured
az account show

# Deploy to Azure
bash scripts/install.sh examples/azure-config.tfvars
```

### GCP Quick Start
```bash
# Prerequisites: gcloud CLI configured
gcloud auth list

# Deploy to GCP
bash scripts/install.sh examples/gcp-config.tfvars
```

## Troubleshooting

### Check Deployment Status
```bash
# Overall status
terraform output

# Pod status
kubectl get pods -n btp-deps -o wide

# Service endpoints
kubectl get endpoints -n btp-deps

# Ingress status
kubectl describe ingress -n btp-deps
```

### View Logs
```bash
# Application logs
kubectl logs -n btp-deps deployment/your-app

# System logs
kubectl logs -n btp-deps deployment/cert-manager
kubectl logs -n btp-deps deployment/ingress-nginx-controller
```

### Restart Components
```bash
# Restart specific deployment
kubectl rollout restart deployment/your-deployment -n btp-deps

# Wait for rollout
kubectl rollout status deployment/your-deployment -n btp-deps
```

## Getting Help

If you encounter issues:

1. **Check the logs**: `kubectl logs -n btp-deps deployment/component-name`
2. **Run verification**: `bash scripts/verify.sh`
3. **Review configuration**: Check your `.env` file and `tfvars` file
4. **Check prerequisites**: Ensure all tools are properly installed
5. **Review documentation**: Check the troubleshooting guide

## Next Steps

- [Architecture Overview](09-architecture-overview.md) - Understand the system design
- [Configuration Reference](22-api-reference.md) - Customize your deployment
- [Operations Guide](18-operations.md) - Day-to-day operations
- [Security Best Practices](19-security.md) - Secure your deployment

---

*Congratulations! You've successfully deployed BTP Universal Terraform. The platform is now ready for development and testing. For production use, follow the platform-specific deployment guides.*
