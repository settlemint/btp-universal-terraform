# GCP/GKE Testing Guide

## Quick Start

To test the GCP/GKE implementation, run:

```bash
./test-gcp.sh
```

This automated script will guide you through all steps.

## Manual Testing Steps

If you prefer to test manually:

### 1. Set up GCP Project

```bash
# Set your GCP project
export PROJECT_ID="your-gcp-project-id"
gcloud config set project $PROJECT_ID

# Authenticate
gcloud auth application-default login
```

### 2. Enable Required APIs

```bash
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable redis.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable servicenetworking.googleapis.com
```

### 3. Update Configuration

Edit `test-gcp.tfvars` and replace all instances of `YOUR_GCP_PROJECT_ID` with your actual project ID:

```bash
sed -i "s/YOUR_GCP_PROJECT_ID/$PROJECT_ID/g" test-gcp.tfvars
```

### 4. Set Environment Variables

Edit `.env` and set these minimum required variables:

```bash
TF_VAR_postgres_password="secure-password-min-8-chars"
TF_VAR_redis_password="secure-password-min-16-chars"
TF_VAR_grafana_admin_password="secure-password-min-12-chars"
TF_VAR_oauth_admin_password="secure-password-min-16-chars"
TF_VAR_jwt_signing_key="random-32-char-string-for-jwt"
TF_VAR_state_encryption_key="random-32-char-string-for-state"
TF_VAR_ipfs_cluster_secret="64-char-hex-string-0123456789abcdef..."
TF_VAR_license_username="test-user"
TF_VAR_license_password="test-pass"
TF_VAR_license_signature="test-sig"
TF_VAR_license_email="test@example.com"
TF_VAR_license_expiration_date="2026-12-31"
```

### 5. Load Environment Variables

```bash
set -a
source .env
set +a
```

### 6. Run Terraform Plan

```bash
terraform plan -var-file=test-gcp.tfvars
```

### 7. Deploy Infrastructure

```bash
terraform apply -var-file=test-gcp.tfvars
```

Expected deployment time: **15-20 minutes**

### 8. Verify Deployment

```bash
# Configure kubectl
gcloud container clusters get-credentials btp-test-cluster \
  --region=us-central1 --project=$PROJECT_ID

# Check nodes
kubectl get nodes

# Check namespaces
kubectl get namespaces

# Check pods
kubectl get pods -A

# View outputs
terraform output
```

## What Gets Deployed

The test configuration deploys a minimal stack:

### Infrastructure
- **GKE Cluster**: 1-3 node autoscaling pool (e2-medium instances)
- **Cloud SQL PostgreSQL**: db-f1-micro instance (smallest tier)
- **Memorystore Redis**: 1GB BASIC tier
- **Cloud Storage**: Single bucket with auto-generated name

### Kubernetes Components
- **cert-manager**: For TLS certificate management
- **nginx-ingress**: For ingress/load balancing
- **kube-prometheus-stack**: Monitoring (Prometheus, Grafana, AlertManager)
- **Loki**: Log aggregation

### NOT Deployed (BTP Disabled)
- SettleMint BTP platform (disabled in test config)

## Cost Estimate

Approximate monthly costs for test deployment:

| Resource | Cost/Month (US) |
|----------|-----------------|
| GKE cluster (1-3 nodes) | $70-150 |
| Cloud SQL (db-f1-micro) | $15 |
| Memorystore Redis (1GB BASIC) | $30 |
| Cloud Storage | <$1 |
| Networking (egress) | $5-10 |
| **Total** | **~$120-200/month** |

**Important**: Destroy resources when not in use to avoid charges!

## Troubleshooting

### API Not Enabled Error
```
Error: Error creating instance: googleapi: Error 403: Access Not Configured...
```

**Solution**: Enable the required API:
```bash
gcloud services enable [api-name].googleapis.com
```

### Authentication Error
```
Error: oauth2: "invalid_grant" "Bad Request"
```

**Solution**: Re-authenticate:
```bash
gcloud auth application-default login
```

### Project ID Not Set
```
Error: Failed to retrieve project, pid: , err: project: required field is not set
```

**Solution**: Update all `YOUR_GCP_PROJECT_ID` in `test-gcp.tfvars` with your actual project ID.

### Quota Exceeded
```
Error: Quota '...' exceeded. Limit: X.0
```

**Solution**:
1. Request quota increase in GCP Console
2. Or use a different region with available quota

### Private Service Connection Required (for Cloud SQL private IP)
```
Error: Error, failed to create service networking connection...
```

**Solution**: If using private networking, you need to create a private service connection first. For testing, use public IPs (`ipv4_enabled = true`).

## Testing with DNS (Optional)

If you have a real domain, you can test DNS integration:

1. Create a Cloud DNS managed zone:
```bash
gcloud dns managed-zones create btp-zone \
  --dns-name="test-btp.example.com." \
  --description="BTP test zone"
```

2. Update `test-gcp.tfvars`:
```hcl
dns = {
  mode = "gcp"
  gcp = {
    project        = "your-project-id"
    managed_zone   = "btp-zone"
    main_record_value = "LOAD_BALANCER_IP" # Get from: kubectl get svc -n btp-deps ingress-nginx-controller
  }
}
```

3. Update your domain's nameservers to use Cloud DNS nameservers (from managed zone details).

## Cleanup

To destroy all resources:

```bash
terraform destroy -var-file=test-gcp.tfvars
```

**Warning**: This will delete all resources including:
- GKE cluster and all workloads
- Cloud SQL database (all data lost)
- Cloud Storage bucket (all files lost)
- Redis instance (all cache data lost)

## Next Steps After Successful Test

1. **Enable BTP Platform**: Set `btp.enabled = true` in config
2. **Configure Production Settings**:
   - Use larger instance types
   - Enable high availability (REGIONAL availability_type)
   - Enable private networking
   - Set up proper DNS
   - Configure OAuth credentials
3. **Set up CI/CD**: Integrate with your deployment pipeline
4. **Configure Monitoring**: Set up alerts in Grafana
5. **Backup Strategy**: Configure automated backups for Cloud SQL

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review GCP logs: `gcloud logging read`
3. Check Terraform state: `terraform show`
4. Review GCP Console for resource status
