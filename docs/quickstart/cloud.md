# Quickstart — Cloud Profiles

Time to complete: ~20–40 minutes (varies by provider)

What you’ll do
- Choose a profile (all-managed or a mix) and deploy across AWS, Azure, or GCP
- Verify endpoints and credentials from Terraform outputs

Prerequisites
- Terraform 1.6+
- Remote state backend configured (recommended)
- Cloud credentials with least-privilege roles

Credential setup
- AWS: `aws configure` or `AWS_PROFILE=...` with permissions for RDS, ElastiCache, S3, ALB/ACM, CloudWatch
- Azure: `az login` with roles for PG Flexible Server, Cache, Storage, Key Vault, App Gateway, Log Analytics
- GCP: `gcloud auth application-default login` with roles for Cloud SQL, Memorystore, GCS, LB/Certs, Logging/Monitoring

Remote state examples
```hcl
# AWS S3 backend
terraform {
  backend "s3" {
    bucket = "btp-tfstate"
    key    = "envs/prod/terraform.tfstate"
    region = "eu-west-1"
    dynamodb_table = "btp-tf-locks"
  }
}
```

Steps
1) Pick a profile (below), save as `my-env.tfvars`.
2) `terraform init`
3) `terraform plan -var-file my-env.tfvars`
4) `terraform apply -var-file my-env.tfvars`

Profiles
- All‑AWS managed: `docs/examples/aws-all-managed.md`
- All‑Azure managed: `docs/examples/azure-all-managed.md`
- All‑GCP managed: `docs/examples/gcp-all-managed.md`
- Mixed: `docs/examples/mixed-aks-s3-cloudsql.md`
- All k8s: `docs/examples/k8s-only.md`
- BYO: `docs/examples/byo-only.md`

Architecture views
- AWS (managed): docs/architecture/aws-full.md
- Azure (managed): docs/architecture/azure-full.md
- GCP (managed): docs/architecture/gcp-full.md
Verification
- Check Terraform outputs for endpoints and credentials (sensitive values redacted)
- Validate k8s ingress and app health via provider DNS/domains

Teardown
```bash
terraform destroy -var-file my-env.tfvars
```
