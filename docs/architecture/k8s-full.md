# Architecture — Full Kubernetes (All k8s mode)

```mermaid
%%{init: {'theme':'neutral','securityLevel':'loose','flowchart':{'htmlLabels':true,'curve':'basis'}}}%%
flowchart TB
  classDef k8s fill:#F7F7F7,stroke:#326CE5,stroke-width:2px

  U["<b>User</b>"]

  subgraph K8s_Cluster["<img src='../assets/icons/k8s/k8s.svg' width='18'/> Kubernetes"]
    direction TB
    subgraph Ingress_TLS
      direction LR
      NGINX["<img src='../assets/icons/k8s/ingress.svg' width='18'/> NGINX Ingress"]
      CERT["<img src='../assets/icons/k8s/cert-manager.svg' width='18'/> cert-manager (TLS)"]
    end
    BTP["<img src='../assets/icons/btp/btp.svg' width='18'/> BTP (UI/API/Workers)"]
    subgraph Deps
      direction LR
      PG["<img src='../assets/icons/k8s/postgres.svg' width='18'/> Postgres (Zalando)"]
      RS["<img src='../assets/icons/k8s/redis.svg' width='18'/> Redis (Bitnami)"]
      MINIO["<img src='../assets/icons/k8s/minio.svg' width='18'/> MinIO (Object Storage)"]
      KC["<img src='../assets/icons/k8s/keycloak.svg' width='18'/> Keycloak (OAuth)"]
      VAULT["<img src='../assets/icons/k8s/vault.svg' width='18'/> Vault (Dev)"]
      PROM["<img src='../assets/icons/k8s/prometheus.svg' width='18'/> Prometheus"]
      LOKI["<img src='../assets/icons/k8s/loki.svg' width='18'/> Loki"]
      PT["<img src='../assets/icons/k8s/promtail.svg' width='18'/> Promtail"]
    end
  end
  class K8s_Cluster k8s

  U -->|HTTPS| NGINX
  NGINX --> BTP

  %% Data/Control paths
  BTP --> PG
  BTP --> RS
  BTP --> MINIO
  BTP --> KC
  BTP --> VAULT
  BTP --> PROM
  BTP --> LOKI
  PT --> LOKI

  %% Certs
  CERT -. issues .- NGINX
```

Notes
- All dependencies run in cluster via Helm charts for speed and simplicity.
- Self-signed issuer for local; switch to ACME/real certs for shared environments.
