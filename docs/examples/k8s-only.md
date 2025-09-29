# Example — All k8s

Deploy all dependencies as Helm charts within the cluster.

```mermaid
flowchart LR
  K8s-->Helm[Helm: DB, Redis, MinIO, OAuth, Prom/EFK]
  Helm-->BTP
```

