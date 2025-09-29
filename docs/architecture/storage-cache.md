# Storage & Cache

Postgres, object storage, and Redis across providers and k8s.

```mermaid
flowchart LR
  App -->|SQL| PG[(Postgres)]
  App -->|Objects| OBJ[(Object Storage)]
  App -->|Cache| REDIS[(Redis)]
```

