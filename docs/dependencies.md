# Dependencies

**Each dependency supports managed, Kubernetes, or bring-your-own modes. All emit consistent output objects.**

## Available modes by dependency

| Dependency | AWS | Kubernetes | Bring-your-own | Notes |
|------------|-----|------------|----------------|-------|
| Postgres | ✓ | ✓ | ✓ | AWS RDS or Zalando Operator |
| Redis | ✓ | ✓ | ✓ | ElastiCache or Bitnami chart |
| Object Storage | ✓ | ✓ | ✓ | S3 or MinIO |
| OAuth | ✓ | ✓ | ✓ | Cognito or Keycloak |
| Secrets | — | ✓ | ✓ | Vault (k8s), AWS Secrets Manager planned |
| Ingress/TLS | — | ✓ | — | ingress-nginx + cert-manager |
| Metrics/Logs | — | ✓ | — | kube-prometheus-stack + Loki |

**Azure and GCP** managed modes are not yet implemented. Use bring-your-own for those clouds.

## Choosing a mode

**Managed (`mode = "aws"`)** – Terraform provisions the backing service
- Use on AWS when you want automated infrastructure
- Requires `vpc.aws` configuration

**Kubernetes (`mode = "k8s"`)** – Helm chart installs inside cluster
- Use for local development
- Use when you want everything in-cluster
- Ensure sufficient cluster capacity and storage classes

**Bring-your-own (`mode = "byo"`)** – External endpoints
- Use when another team manages the dependency
- Provide stable endpoints and credentials in tfvars

## Ingress and TLS configuration

**Toggle Let's Encrypt environment**
```bash
ingress_tls.k8s.acme_environment = "staging"  # or "production"
```

**Staging is useful for testing**
- Avoids production rate limits
- Use while iterating on configuration

**Match issuer name to environment**
- `letsencrypt-staging` for staging
- `letsencrypt-prod` for production
- cert-manager generates a fresh certificate order

## Output contract

**Outputs return Terraform objects**, not raw strings
- Avoid string parsing where possible

**Sensitive fields** are marked `sensitive = true`
- Passwords, tokens, client secrets
- Prevents accidental logging

**Provider-specific metadata** nested under `metadata` map
- Allows future extensibility
- Keeps core contract stable
