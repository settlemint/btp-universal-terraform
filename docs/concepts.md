# Concepts

**Mix managed cloud services, in-cluster Helm charts, and external endpoints without changing how BTP consumes infrastructure.**

## Three dependency modes

Each dependency supports:

**Managed** – Cloud provider services
- AWS: RDS, ElastiCache, S3, Cognito
- Azure and GCP: Planned

**Kubernetes** – In-cluster Helm charts
- Zalando Postgres Operator
- Bitnami Redis
- MinIO, Keycloak, Vault
- kube-prometheus-stack, Loki

**Bring-your-own** – External endpoints
- Provide connection details in tfvars
- Use when another team manages the service

**Mix modes freely.** Run RDS for Postgres and in-cluster Redis in the same deployment.

```mermaid
%%{init: {'theme':'neutral','securityLevel':'loose','flowchart':{'htmlLabels':true,'curve':'basis'}}}%%
flowchart TD
  start[Select mode per dependency]
  start --> managed["Managed services"]
  start --> k8s["Kubernetes Helm charts"]
  start --> byo["Bring-your-own endpoints"]
  managed --> outputs["Normalized outputs"]
  k8s --> outputs
  byo --> outputs
```

## Normalized outputs contract

**Dependencies return consistent objects regardless of mode:**
- `host`, `port`
- `credentials`
- `tls`
- Provider-specific metadata

**The BTP module consumes these outputs** without conditional logic.

**Sensitive values** are flagged so Terraform masks them.

## Configuration

**Root module inputs** accept one `mode` per dependency plus optional provider-specific `config` blocks.

**tfvars files** are the primary way to select modes and override defaults.

**State backends** should separate environments to avoid accidental cross-talk.

## Cross-cloud composition

**Mix `aws`, `k8s`, and `byo` modes** to fit each environment.

**Cloud scaffolding modules** (`cloud/aws`, planned for Azure/GCP) expose networking and IAM helpers.

**Dependencies never reach across provider boundaries.** The root module orchestrates multiple dependency modules.

## Environment strategy

**Local profiles** – Validate charts and ingress quickly

**Shared environments** – Pin tfvars and use remote state backends (Terraform Cloud, S3, GCS)

**Secrets** – Track in provider secret managers or external vaults, never in tfvars or logs
