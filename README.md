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

This repository provides a consistent Terraform flow to provision BTP platform dependencies and install the BTP Helm chart. Use the same module to deploy to AWS, Azure, and GCP or any existing Kubernetes cluster. Each dependency can be provided via a managed cloud service, installed inside Kubernetes (Helm), or wired to your own (BYO) endpoints.

For deeper guidance, dive into the in-repo docs starting at [`docs/README.md`](./docs/README.md).

### Key Features

- 🧭 Unified module layout for dependencies with three modes: k8s (Helm) | managed (cloud) | byo (external)
- 🪄 Consistent `-var-file` based configuration across environments
- 🔐 Secrets flow through `TF_VAR_*` inputs, and Terraform marks sensitive outputs automatically
- 📈 Observability stack via kube-prometheus-stack and Loki
- 📚 Maintained docs under `docs/` covering configuration, operations, and troubleshooting

## Quick Start

### Configuration Files

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
terraform plan  -var-file examples/k8s-config.tfvars
terraform apply -var-file examples/k8s-config.tfvars

# Tear down when finished
terraform destroy -var-file examples/k8s-config.tfvars
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
terraform apply -var-file examples/k8s-config.tfvars
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
terraform plan -var-file examples/generic-orbstack-dev.tfvars
terraform apply -var-file examples/generic-orbstack-dev.tfvars
```

- Destroy when finished:

```bash
terraform destroy -var-file examples/generic-orbstack-dev.tfvars
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
