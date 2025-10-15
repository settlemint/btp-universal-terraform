# Dependencies

Each dependency follows the three-mode pattern and emits a consistent output object. The table below reflects what is implemented right now.

| Dependency     | Modes ready         | Notes |
|----------------|---------------------|-------|
| Postgres       | `aws`, `k8s`, `byo` | AWS RDS provisioning ships today. Azure and GCP files are placeholders—use BYO connection details for those clouds. |
| Redis          | `aws`, `k8s`, `byo` | Supports ElastiCache, Bitnami Helm chart, or external Redis endpoints. Azure/GCP managed paths still TODO. |
| Object Storage | `aws`, `k8s`, `byo` | Creates S3 buckets or deploys MinIO. Other providers require existing buckets and credentials via BYO. |
| OAuth          | `aws`, `k8s`, `byo` | AWS Cognito and Keycloak integrations exist; Azure/GCP implementations are placeholders awaiting contributions. |
| Secrets        | `k8s`, `byo`        | Ships with Vault-on-Kubernetes and BYO secret backends. AWS/Azure/GCP managed secret stores are not wired yet. |
| Ingress/TLS    | `k8s`               | Installs ingress-nginx and cert-manager with optional Route53 DNS-01 automation. No cloud load balancer automation yet. |
| Metrics/Logs   | `k8s`               | Installs kube-prometheus-stack and Loki. Managed observability integrations are planned. |

## Picking a mode
- Prefer managed (`mode = "aws"`) when you run on AWS and want Terraform to provision the backing service.
- Use `k8s` mode for local development or when you want everything inside the cluster.
- Choose `byo` when another team already operates the dependency and can supply stable endpoints and credentials.

## Outputs contract notes
- Outputs return Terraform objects; avoid parsing raw strings wherever possible.
- Sensitive fields (passwords, tokens, client secrets) surface as `sensitive = true` to prevent accidental logging.
- Additional provider-specific metadata is nested under each dependency's `metadata` map for future extensibility.
