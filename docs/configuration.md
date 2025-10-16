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
- Sensitive values are defined under “Credentials and secret inputs” in `variables.tf`. Supply them with `TF_VAR_*` environment variables before running Terraform; do not place them in tfvars.
- Vault (k8s mode) defaults to dev mode for quick trials. Pass `secrets.k8s.dev_mode = false` in a tfvars file before using it beyond experimentation, and wire an external storage backend via `secrets.k8s.values`.
- AWS Route53 DNS automation needs `TF_VAR_aws_access_key_id` and `TF_VAR_aws_secret_access_key` unless you rely on the instance/role profile. Those credentials are only written into a Kubernetes secret in the ingress namespace.

## Picking an example
- `examples/k8s-config.tfvars`: all dependencies in k8s mode for local clusters (OrbStack, kind, minikube).
- `examples/aws-config.tfvars`: AWS managed services plus ingress TLS via Route53. Update subnet IDs, Route53 zone, and callback URLs before applying.
- `examples/mixed-config.tfvars`: demonstrates mixing AWS managed Postgres/Redis with in-cluster dependencies.
- `examples/azure-config.tfvars` and `examples/gcp-config.tfvars`: show how to supply BYO endpoints for those clouds today.
- `examples/byo-config.tfvars`: fully external dependencies for teams layering Terraform on top of existing services.
