<p align="center">
  <img src="https://github.com/settlemint/sdk/blob/main/logo.svg" width="200px" align="center" alt="SettleMint logo" />
  <h1 align="center">SettleMint – BTP Universal Terraform</h1>
  <p align="center">
    ✨ <a href="https://settlemint.com">https://settlemint.com</a> ✨
    <br/>
    Standardized, auditable Terraform to provision platform dependencies and deploy SettleMint BTP across clouds.
    <br/>
    Works with AWS, Azure, GCP, and any Kubernetes cluster. Mix managed, Kubernetes (Helm), or bring‑your‑own backends per dependency.
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
</div>

## Introduction

This repository provides a consistent Terraform flow to provision BTP platform dependencies and install the BTP Helm chart. Use the same module to deploy to AWS, Azure, and GCP or any existing Kubernetes cluster. Each dependency can be provided via a managed cloud service, installed inside Kubernetes (Helm), or wired to your own (BYO) endpoints.

### Key Features

- 🧭 Unified module layout for dependencies with three modes: k8s (Helm) | managed (cloud) | byo (external)
- 🪄 One-command apply with `-var-file` environment configs
- 🔐 Secure defaults: random passwords, TLS issuer, sensitive outputs
- 📈 Observability stack via kube-prometheus-stack and Loki
- 🧪 Preflight checks to validate local cluster and Helm repos

## Quick Start

### One‑liner Install

Run a full install (preflight + init + apply) using your chosen tfvars:

```bash
bash scripts/install.sh examples/generic-orbstack-dev.tfvars
```

Replace the tfvars with your environment file (e.g., `examples/aws-dev.tfvars`, `examples/azure-dev.tfvars`, `examples/gcp-dev.tfvars`, or a custom file).

### Manual Apply

```bash
# Optional: Preflight checks (kubectl/helm, helm repos)
./scripts/preflight.sh

# Initialize Terraform
terraform init

# Review plan and apply using the OrbStack example
terraform plan  -var-file examples/generic-orbstack-dev.tfvars
terraform apply -var-file examples/generic-orbstack-dev.tfvars
```

## Typical development workflow

- Edit module code under `./deps/*` or root variables/outputs
- Format and validate:

```bash
terraform fmt -recursive && terraform validate
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

You can run a deeper end-to-end verification:

```bash
bash scripts/verify.sh btp-deps
```

### Namespaces

- Dependencies deploy to `btp-deps` by default (override per dependency via `var.<dep>.k8s.namespace` or `var.namespaces`).
- The BTP chart deploys to `btp` by default (configurable in `btp_helm` module).

## Architecture Overview

- Root module wires dependency modules and normalizes outputs
- Modules:
  - `./deps/{postgres,redis,object_storage,oauth,secrets,ingress_tls,metrics_logs}` implement the three-mode pattern
  - `./btp_helm` (stub) will map normalized outputs to BTP chart values
- Examples in `./examples/*.tfvars` (generic examples included; cloud examples can be added per team)

Note: `cluster.create` is present for future cloud scaffolding but not implemented yet in the root module.

## Quality Assurance

```bash
terraform fmt -recursive   # formatting
terraform validate         # static validation
# Lint (TFLint)
bash scripts/lint.sh       # runs `tflint --init` + `tflint`
# Optional security scan (if installed)
checkov -d .
```

Before PRs: include plan output for the example tfvars and note any input/output changes. See `AGENTS.md` for conventions.

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

## Dev Defaults vs Production

These modules default to development-friendly settings:
- Persistence disabled for databases and observability
- Ingress uses NodePort and a self-signed ClusterIssuer
- Vault runs in dev mode with a known token
- Redis/MinIO without TLS

Do not use these defaults in production; override via `values` and enable persistence, TLS, and proper authentication as needed.
