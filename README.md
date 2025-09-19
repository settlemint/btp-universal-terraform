<p align="center">
  <img src="https://github.com/settlemint/sdk/blob/main/logo.svg" width="200px" align="center" alt="SettleMint logo" />
  <h1 align="center">SettleMint – BTP Universal Terraform</h1>
  <p align="center">
    ✨ <a href="https://settlemint.com">https://settlemint.com</a> ✨
    <br/>
    Standardized, auditable Terraform to provision platform dependencies and deploy SettleMint BTP.
    <br/>
    Helm-first on OrbStack for local; extensible to AWS, Azure, and GCP.
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

This repository provides a consistent Terraform flow to provision BTP platform dependencies and install the BTP Helm chart. It standardizes deployment across environments, with a Helm-first workflow that runs great on OrbStack/local and a structure that cleanly extends to cloud deployments (AWS, Azure, GCP) and BYO integrations.

### Key Features

- 🧭 Unified module layout for dependencies following a three‑mode pattern (k8s | managed | byo)
- 🪄 One-command apply with `-var-file` environment configs
- 🔐 Secure defaults: random passwords, TLS issuer, sensitive outputs
- 📈 Observability stack via kube-prometheus-stack and Loki
- 🧪 Preflight checks to validate local cluster and Helm repos

## Local development

### One‑liner Install

Run a complete local install (preflight + init + apply) with one command:

```bash
bash scripts/install.sh
```

Optionally specify a different vars file:

```bash
bash scripts/install.sh examples/generic-orbstack-dev.tfvars
```

### Setting up (OrbStack)

```bash
# Preflight checks and helm repo setup
./scripts/preflight.sh

# Initialize Terraform
terraform init

# Review plan and apply using the OrbStack example
terraform plan  -var-file examples/generic-orbstack-dev.tfvars
terraform apply -var-file examples/generic-orbstack-dev.tfvars
```

### Typical development workflow

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

### Smoke checks (local)

- Ingress controller ready; cert-manager `ClusterIssuer` exists
- Postgres/Redis services resolvable in-cluster; MinIO UI/API reachable
- Grafana accessible; Prometheus up; Loki receiving logs
- Keycloak admin reachable; Vault server responding (dev mode)

### Namespaces

- Dependencies deploy to `btp-deps` by default (override per dependency via `var.<dep>.k8s.namespace` or `var.namespaces`).
- The BTP chart deploys to `btp` by default (configurable in `btp_helm` module).

## Architecture Overview

- Root module wires dependency modules and normalizes outputs
- Modules:
  - `./deps/{postgres,redis,object_storage,oauth,secrets,ingress_tls,metrics_logs}`
  - `./btp_helm` (maps normalized outputs to BTP chart values)
- Examples in `./examples/*.tfvars` (start with `generic-orbstack-dev.tfvars`)

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
