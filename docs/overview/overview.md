# Overview

The BTP Universal Terraform stack runs BTP on Kubernetes and wires in cloud services (or self-hosted charts) through a single, stable contract. Every dependency — Postgres, Redis, Object Storage, OAuth, Secrets, Ingress/TLS, Metrics/Logs — supports managed | k8s | byo, and you can mix providers freely.

Why this is different
- One interface, many providers: switch modes without touching app config
- Secure by default: TLS-first, least-privilege, external secrets by design
- Fast local iteration: one cluster, Helm dependencies, ship in minutes
- Consistent outputs: `/btp` reads unified outputs and “just works”

Supported matrix
- Providers: AWS, Azure, GCP, Generic (local)
- Modes (per dependency): managed | k8s | byo

```mermaid
%%{init: {'theme':'neutral','securityLevel':'loose','flowchart':{'htmlLabels':true}}}%%
flowchart LR
  classDef aws fill:#F7F7F7,stroke:#FF9900,stroke-width:2px
  classDef azure fill:#F7F7F7,stroke:#0078D4,stroke-width:2px
  classDef gcp fill:#F7F7F7,stroke:#EA4335,stroke-width:2px
  classDef k8s fill:#F7F7F7,stroke:#326CE5,stroke-width:2px

  subgraph K8s_Cluster
    app["<img src='../assets/icons/k8s/k8s.svg' width='18'/> BTP Helm Release"]
    ing["<img src='../assets/icons/k8s/ingress.svg' width='18'/> Ingress + TLS"]
  end
  class K8s_Cluster k8s

  subgraph AWS
    s3["<img src='../assets/icons/aws/s3.svg' width='18'/> Object Storage (S3)"]
    rds["<img src='../assets/icons/aws/rds.svg' width='18'/> Postgres (RDS)"]
  end
  class AWS aws

  subgraph Azure
    kv["<img src='../assets/icons/azure/key-vault.svg' width='18'/> Secrets (Key Vault)"]
  end
  class Azure azure

  subgraph GCP
    csql["<img src='../assets/icons/gcp/cloud-sql.svg' width='18'/> Postgres (Cloud SQL)"]
  end
  class GCP gcp

  ing --> app
  app --> rds
  app --> s3
  app --> kv
  app --> csql
  app --> REDIS["<img src='../assets/icons/k8s/redis.svg' width='18'/> Redis"]
  app --> VAULT["<img src='../assets/icons/k8s/vault.svg' width='18'/> Secrets"]
  app --> OBJ["<img src='../assets/icons/k8s/minio.svg' width='18'/> Object Storage"]
```

## Key Capabilities
- Mix providers per dependency (e.g., AKS + S3 + Cloud SQL)
- Stable outputs contract across modes/providers for `/btp`
- Preflight checks, environment profiles, and example `*.tfvars`

Next steps
- Get running locally: docs/quickstart/local.md
- Plan and apply a cloud profile: docs/quickstart/cloud.md
- Explore full architectures:
  - AWS (managed): docs/architecture/aws-full.md
  - Azure (managed): docs/architecture/azure-full.md
  - GCP (managed): docs/architecture/gcp-full.md
  - Kubernetes only: docs/architecture/k8s-full.md
