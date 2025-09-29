# Identity & Secrets

OAuth providers and secrets backends across clouds and k8s.

```mermaid
flowchart TD
  App -->|OIDC| OAuth[OAuth Provider]
  App -->|Read/Write| Secrets[Secrets Backend]
```

