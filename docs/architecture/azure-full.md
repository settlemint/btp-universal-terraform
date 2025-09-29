# Architecture — Full Azure (All Managed)

```mermaid
%%{init: {'theme':'neutral','securityLevel':'loose','flowchart':{'htmlLabels':true,'curve':'basis'}}}%%
flowchart TB
  classDef azure fill:#F7F7F7,stroke:#0078D4,stroke-width:2px
  classDef k8s fill:#F7F7F7,stroke:#326CE5,stroke-width:2px

  U["<b>User</b>"]

  subgraph Azure
    direction TB
    subgraph Ingress_TLS
      direction LR
      AGW["<img src='../assets/icons/azure/app-gateway.svg' width='18'/> App Gateway (Ingress)"]
      KV["<img src='../assets/icons/azure/key-vault.svg' width='18'/> Key Vault (TLS/Secrets)"]
    end
    subgraph AKS["<img src='../assets/icons/azure/aks.svg' width='18'/> AKS (Kubernetes)"]
      BTP["<img src='../assets/icons/btp/btp.svg' width='18'/> BTP (UI/API/Workers)"]
    end
    subgraph Deps
      direction LR
      PG["<img src='../assets/icons/azure/postgres-flexible.svg' width='18'/> PostgreSQL Flexible Server"]
      RC["<img src='../assets/icons/azure/cache-redis.svg' width='18'/> Azure Cache for Redis"]
      BLOB["<img src='../assets/icons/azure/storage-blob.svg' width='18'/> Blob Storage"]
      ENTRA["<img src='../assets/icons/azure/entra.svg' width='18'/> Entra ID (OAuth)"]
      LA["<img src='../assets/icons/azure/log-analytics.svg' width='18'/> Log Analytics"]
    end
  end
  class Azure azure

  U -->|HTTPS| AGW
  AGW --> BTP

  %% Data/Control paths
  BTP --> PG
  BTP --> RC
  BTP --> BLOB
  BTP --> ENTRA
  BTP --> KV
  BTP --> LA

  %% Certs
  KV -. certs .- AGW
```

Notes
- Ingress via Application Gateway; TLS/certs in Key Vault.
- Managed services across data, cache, storage, identity, and observability.
- BTP in Kubernetes reads unified outputs to configure connectivity.
