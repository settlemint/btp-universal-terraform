# Configuration Guide

This page highlights the Terraform inputs you normally touch when preparing an environment. Use the example tfvars files in `examples/` as a starting point and only override what differs for your workspace.

## Core inputs
- `platform` (see `variables.tf`): pick `aws`, `azure`, `gcp`, or `generic`. Today only the AWS path provisions managed infrastructure; the others assume Kubernetes or bring-your-own endpoints.
- `base_domain`: hostname suffix for ingress. Local clusters often use `127.0.0.1.nip.io`; cloud profiles point to a routed domain.
- `namespaces`: optional overrides when you want each dependency deployed into a dedicated namespace instead of the default `btp-deps`.

## Infrastructure orchestration
- `vpc`: wiring for the AWS cloud scaffolding (`cloud/aws`). Leave it empty for local Kubernetes; populate the `aws` object when `platform = "aws"` so subnets and security groups exist for managed dependencies. Set `create_vpc = false` and supply existing IDs when reusing networking.
- `k8s_cluster`: controls the `deps/k8s_cluster` module. Supported modes are `aws` (EKS), `byo` (existing kubeconfig), or `disabled`. Azure and GCP blocks are placeholders; keep the mode on `byo` if you already operate the cluster.
- The cluster module outputs a rendered kubeconfig (`outputs.tf:82`). Export it to verify workloads whenever Terraform created the control plane.

## Dependency modes
- Every dependency block in `variables.tf` accepts a `mode` plus provider-specific configuration. Defaults are `k8s` for everything except DNS (`byo`) and OAuth (`disabled`).
- Managed implementations ship for AWS across Postgres, Redis, Object Storage, and OAuth. Kubernetes mode deploys Helm charts (Zalando Postgres operator, Bitnami Redis, MinIO, Keycloak, Vault, kube-prometheus-stack, ingress-nginx + cert-manager).
- BYO mode expects you to provide connection details and credentials. Use it for Azure/GCP today or when another team operates the service.
- When you flip a dependency to AWS managed, make sure `vpc.aws` is populated so subnet groups and security groups resolve. Terraform reuses values passed in `examples/aws-config.tfvars`.

## DNS and ingress
- `dns`: defaults to `mode = "byo"` which only returns helper outputs. Set `mode = "aws"` and provide a Route53 zone to let Terraform create records that match the ingress module outputs.
- `ingress_tls`: manages ingress-nginx and cert-manager. Provide `acme_email` and, for AWS DNS automation, a `route53_credentials_secret_name` plus AWS credentials injected via environment variables (see the AWS access key inputs in `variables.tf`).
- Wildcard certificates are derived automatically when the DNS module knows the base domain (`main.tf:45`). Override `default_certificate` in the ingress module if you need a different secret name.

## Secrets and credentials

Sensitive values are defined under "Credentials and secret inputs" in `variables.tf`. Never commit secrets to version control or store them in tfvars files. Instead, supply them via environment variables that Terraform reads automatically.

### Using environment variables

Terraform automatically reads any environment variable prefixed with `TF_VAR_` and maps it to the corresponding Terraform variable. For example, `TF_VAR_postgres_password` becomes the `postgres_password` variable.

**Method 1: Export variables in your shell**

```bash
export TF_VAR_postgres_password="your-secure-password"
export TF_VAR_redis_password="your-redis-password"
# ... export other variables
terraform apply -var-file examples/k8s-config.tfvars
```

**Method 2: Use a `.env` file**

Create a `.env` file from the provided example:

```bash
cp .env.example .env
# Edit .env with your actual values (do not commit this file!)
```

Load the environment variables before running Terraform:

```bash
# Using set command (recommended for most shells)
set -a && source .env && set +a
terraform apply -var-file examples/k8s-config.tfvars

# Alternative: inline with env command
env $(cat .env | xargs) terraform apply -var-file examples/k8s-config.tfvars
```

**Method 3: Integrate with a password manager**

Many password managers support injecting secrets into your environment. Example with 1Password CLI:

```bash
# In .env, use op:// references:
# TF_VAR_postgres_password=op://vault/item/password

op run --env-file=.env -- terraform apply -var-file examples/k8s-config.tfvars
# If you have multiple accounts: op run --account <shorthand> --env-file=.env -- terraform apply
```

This pattern works with other password managers that offer CLI tools (Bitwarden, LastPass, AWS Secrets Manager, HashiCorp Vault, etc.). Check your password manager's documentation for environment variable injection capabilities.

### Required credentials

Check `.env.example` for the complete list. The essential variables are:

- Dependency credentials: `TF_VAR_postgres_password`, `TF_VAR_redis_password`, `TF_VAR_object_storage_access_key`, `TF_VAR_object_storage_secret_key`
- Observability: `TF_VAR_grafana_admin_password`
- OAuth: `TF_VAR_oauth_admin_password`
- Platform secrets: `TF_VAR_jwt_signing_key`, `TF_VAR_ipfs_cluster_secret`, `TF_VAR_state_encryption_key`
- License: `TF_VAR_license_username`, `TF_VAR_license_password`, `TF_VAR_license_signature`, `TF_VAR_license_email`, `TF_VAR_license_expiration_date`

See `variables.tf` for validation rules (minimum lengths, required formats).

### Additional notes

- Vault (k8s mode) defaults to dev mode for quick trials. Pass `secrets.k8s.dev_mode = false` in a tfvars file before using it beyond experimentation, and wire an external storage backend via `secrets.k8s.values`.
- AWS Route53 DNS automation needs `TF_VAR_aws_access_key_id` and `TF_VAR_aws_secret_access_key` unless you rely on the instance/role profile. Those credentials are only written into a Kubernetes secret in the ingress namespace.

## Picking an example
- `examples/k8s-config.tfvars`: all dependencies in k8s mode for local clusters (OrbStack, kind, minikube).
- `examples/aws-config.tfvars`: AWS managed services plus ingress TLS via Route53. Update subnet IDs, Route53 zone, and callback URLs before applying.
- `examples/mixed-config.tfvars`: demonstrates mixing AWS managed Postgres/Redis with in-cluster dependencies.
- `examples/azure-config.tfvars` and `examples/gcp-config.tfvars`: show how to supply BYO endpoints for those clouds today.
- `examples/byo-config.tfvars`: fully external dependencies for teams layering Terraform on top of existing services.
