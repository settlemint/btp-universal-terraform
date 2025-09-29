# Modes: managed | k8s | byo

Each dependency supports three modes with a unified output contract:

- managed: provision cloud-native services (e.g., RDS, Cloud SQL, Key Vault)
- k8s: deploy Helm charts in the target cluster
- byo: consume external endpoints you provide

```mermaid
flowchart TD
  A[Select dependency mode] -->|managed| M[Provision Cloud Service]
  A -->|k8s| K[Deploy Helm Chart]
  A -->|byo| B[Consume External Endpoint]
  M --> O[Emit unified outputs]
  K --> O
  B --> O
```

