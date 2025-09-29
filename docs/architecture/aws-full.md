# Architecture — Full AWS (All Managed)

```mermaid
%%{init: {'theme':'neutral','securityLevel':'loose','flowchart':{'htmlLabels':true,'curve':'basis'}}}%%
flowchart TB
  classDef aws fill:#F7F7F7,stroke:#FF9900,stroke-width:2px
  classDef k8s fill:#F7F7F7,stroke:#326CE5,stroke-width:2px

  U["<b>User</b>"]

  subgraph AWS
    direction TB
    subgraph Ingress_TLS
      direction LR
      ALB["<img src='../assets/icons/aws/alb.svg' width='18'/> ALB (Ingress)"]
      ACM["<img src='../assets/icons/aws/acm.svg' width='18'/> ACM (TLS)"]
    end
    subgraph EKS["<img src='../assets/icons/aws/eks.svg' width='18'/> EKS (Kubernetes)"]
      BTP["<img src='../assets/icons/btp/btp.svg' width='18'/> BTP (UI/API/Workers)"]
    end
    subgraph Deps
      direction LR
      RDS["<img src='../assets/icons/aws/rds.svg' width='18'/> RDS (Postgres)"]
      EC["<img src='../assets/icons/aws/elasticache.svg' width='18'/> ElastiCache (Redis)"]
      S3["<img src='../assets/icons/aws/s3.svg' width='18'/> S3 (Object Storage)"]
      COG["<img src='../assets/icons/aws/cognito.svg' width='18'/> Cognito (OAuth)"]
      SM["<img src='../assets/icons/aws/secrets-manager.svg' width='18'/> Secrets Manager"]
      CW["<img src='../assets/icons/aws/cloudwatch.svg' width='18'/> CloudWatch (Logs/Metrics)"]
    end
  end
  class AWS aws

  U -->|HTTPS| ALB
  ALB --> BTP

  %% Data/Control paths
  BTP --> RDS
  BTP --> EC
  BTP --> S3
  BTP --> COG
  BTP --> SM
  BTP --> CW

  %% Certs
  ACM -. issues .- ALB
```

Notes
- Ingress via ALB; certificates via ACM; DNS via Route53 (not shown).
- Dependencies are fully managed: RDS, ElastiCache, S3, Cognito, Secrets Manager, CloudWatch.
- BTP in Kubernetes consumes unified outputs for all dependencies.
