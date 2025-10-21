# Configuration

**Start with an example tfvars file from `examples/` and customize only what you need.**

## Required inputs

**Platform**
- `platform` – Set to `aws`, `azure`, `gcp`, or `generic`
- AWS provisions managed infrastructure; other platforms use Kubernetes or bring-your-own

**Domain**
- `base_domain` – Hostname suffix for ingress
  - Local: `127.0.0.1.nip.io`
  - Cloud: your routed domain

**Namespaces** (optional)
- `namespaces` – Override to deploy each dependency in a dedicated namespace
- Default: all in `btp-deps`

## AWS infrastructure

**VPC**
- `vpc.aws` – Required when `platform = "aws"`
- Set `create_vpc = false` to use existing networking
- Leave empty for local Kubernetes

**Kubernetes cluster**
- `k8s_cluster.mode` – Choose `aws` (EKS), `byo` (existing kubeconfig), or `disabled`
- Terraform outputs kubeconfig at `outputs.tf:82` when it creates the cluster

## Dependency modes

**Each dependency accepts a mode**
- `aws` – Managed services (RDS, ElastiCache, S3, Cognito)
- `k8s` – Helm charts (Zalando Postgres, Bitnami Redis, MinIO, Keycloak, Vault)
- `byo` – Your existing endpoints and credentials

**Defaults**
- Most dependencies: `k8s`
- DNS: `byo`
- OAuth: `disabled`

**For AWS managed mode**, populate `vpc.aws` so subnet groups and security groups resolve.

## DNS and ingress

**DNS**
- Default: `mode = "byo"` (returns helper outputs only)
- AWS: Set `mode = "aws"` and provide Route53 zone ID

**Ingress and TLS**
- `ingress_tls` installs ingress-nginx and cert-manager
- Provide `acme_email` for Let's Encrypt
- For AWS DNS-01 automation, set `route53_credentials_secret_name` and export:
  - `TF_VAR_aws_access_key_id`
  - `TF_VAR_aws_secret_access_key`

**Wildcard certificates** are generated automatically when DNS mode knows the base domain (main.tf:45).

## Secrets and credentials

**Supply sensitive values via environment variables**
```bash
export TF_VAR_grafana_admin_password=...
export TF_VAR_aws_access_key_id=...
export TF_VAR_aws_secret_access_key=...
```

Never put secrets in tfvars files.

**Vault in k8s mode**
- Defaults to dev mode for testing
- Set `secrets.k8s.dev_mode = false` for production
- Configure storage via `secrets.k8s.values`

## Example files

| File | Use case |
|------|----------|
| `k8s-config.tfvars` | Local clusters (OrbStack, kind, minikube) |
| `aws-config.tfvars` | AWS managed services |
| `mixed-config.tfvars` | Mix AWS managed + in-cluster |
| `azure-config.tfvars` | Azure bring-your-own endpoints |
| `gcp-config.tfvars` | GCP bring-your-own endpoints |
| `byo-config.tfvars` | External dependencies |
