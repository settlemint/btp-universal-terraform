# GCP Provider

**Native GCP modules are not implemented yet. Use bring-your-own mode to connect existing Google Cloud services.**

## GCP support is planned

When implemented, the `cloud/gcp` module will provision:
- VPC networks and service accounts
- Cloud SQL
- Memorystore for Redis
- Cloud Storage (GCS)
- Identity Platform
- Secret Manager

## Working with GCP today

**Use `mode = "byo"` for all dependencies**
- Provide endpoints and credentials in tfvars
- Keep ingress, metrics/logs, and secrets in `k8s` mode

**Manage outside Terraform**
- Networking, service accounts, DNS
- All GCP resources
- Feed resulting values into root module inputs

## Roadmap

When adding GCP support:
- Plan for Workload Identity and private service connectivity
- Avoid service account keys where possible
- Document required IAM roles and API enablement
- Support certificate automation for Kubernetes resources
