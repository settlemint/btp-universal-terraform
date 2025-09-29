# Architecture — Full GCP (All Managed)

```mermaid
%%{init: {'theme':'neutral','securityLevel':'loose','flowchart':{'htmlLabels':true,'curve':'basis'}}}%%
flowchart TB
  classDef gcp fill:#F7F7F7,stroke:#EA4335,stroke-width:2px
  classDef k8s fill:#F7F7F7,stroke:#326CE5,stroke-width:2px

  U["<b>User</b>"]

  subgraph GCP
    direction TB
    subgraph Ingress_TLS
      direction LR
      HLB["<img src='../assets/icons/gcp/https-lb.svg' width='18'/> HTTPS LB (Ingress)"]
      CMGR["<img src='../assets/icons/gcp/certificate-manager.svg' width='18'/> Certificate Manager (TLS)"]
    end
    subgraph GKE["<img src='../assets/icons/gcp/gke.svg' width='18'/> GKE (Kubernetes)"]
      BTP["<img src='../assets/icons/btp/btp.svg' width='18'/> BTP (UI/API/Workers)"]
    end
    subgraph Deps
      direction LR
      CSQL["<img src='../assets/icons/gcp/cloud-sql.svg' width='18'/> Cloud SQL (Postgres)"]
      MEM["<img src='../assets/icons/gcp/memorystore.svg' width='18'/> Memorystore (Redis)"]
      GCS["<img src='../assets/icons/gcp/gcs.svg' width='18'/> GCS (Object Storage)"]
      IDP["<img src='../assets/icons/gcp/identity-platform.svg' width='18'/> Identity Platform (OAuth)"]
      SM["<img src='../assets/icons/gcp/secret-manager.svg' width='18'/> Secret Manager"]
      MON["<img src='../assets/icons/gcp/cloud-monitoring.svg' width='18'/> Cloud Monitoring"]
      LOG["<img src='../assets/icons/gcp/cloud-logging.svg' width='18'/> Cloud Logging"]
    end
  end
  class GCP gcp

  U -->|HTTPS| HLB
  HLB --> BTP

  %% Data/Control paths
  BTP --> CSQL
  BTP --> MEM
  BTP --> GCS
  BTP --> IDP
  BTP --> SM
  BTP --> MON
  BTP --> LOG

  %% Certs
  CMGR -. certs .- HLB
```

Notes
- Ingress via HTTPS Load Balancer; certificates via Certificate Manager.
- Managed services across data, cache, storage, identity, secrets, and observability.
- Use Private Service Connect for Cloud SQL; Workload Identity for k8s → GCP APIs.
