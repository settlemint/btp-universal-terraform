# Security Notes

This page covers the controls currently implemented in the Terraform modules.

## Ingress and certificates
- `deps/ingress_tls` installs ingress-nginx and cert-manager with HTTP-01 challenges by default (`deps/ingress_tls/main.tf:63`). DNS-01 via Route53 is enabled only when you set `ingress_tls.k8s.route53_credentials_secret_name` and supply AWS credentials (see the AWS access key variables in `variables.tf`).
- Profile tfvars pick the controller service exposure. Example: `examples/aws-config.tfvars:140` uses `LoadBalancer`, while `examples/k8s-config.tfvars` keeps the chart default. Check the `ingress_tls.k8s.values_nginx` block in your profile to confirm what gets applied.
- Wildcard certificates are optional. Terraform provisions them when the DNS module returns wildcard hostnames (`main.tf:63`); otherwise cert-manager issues per-ingress certificates.

## Data stores
- RDS instances enable encryption at rest and automated backups by default (`deps/postgres/aws.tf:57`).
- ElastiCache can run with transit and at-rest encryption (`deps/redis/aws.tf:45`). Enable `transit_encryption_enabled` and provide an authentication token to require TLS-based clients; otherwise Redis listens in plaintext inside the VPC.
- The S3 module enables server-side encryption and blocks public access on managed buckets (`deps/object_storage/aws.tf:46`). If you reference an existing bucket, verify those settings yourself.
- Kubernetes mode dependencies deploy Helm charts with in-cluster services and default to non-persistent storage. Add persistence and network policies through the `values` overrides when needed.

## Secrets and credentials
- Vault in k8s mode runs in dev mode unless you disable it (`deps/secrets/k8s.tf:19`). Switch `secrets.k8s.dev_mode = false` and wire persistent storage before using it in production.
- Terraform never writes secrets to disk: all sensitive inputs come from the “Credentials and secret inputs” section of `variables.tf`. Keep using `TF_VAR_*` exports or a secret manager integration with Terraform Cloud.
- OAuth managed mode (Cognito) provisions a user pool and client but leaves rotation and MFA policies to the operator. Document your requirements in `examples/aws-config.tfvars` so apply scripts stay aligned.

## IAM and networking
- The AWS cloud scaffolding restricts security groups for Postgres and Redis to traffic from the VPC CIDR and any additional groups you list (`cloud/aws/main.tf:152`). Review those rules when connecting from outside the VPC.
- EKS roles receive the standard AWS-managed policies (`deps/k8s_cluster/aws.tf:24`). Add custom policies through IRSA if workloads need additional AWS API access; Terraform only creates the cluster-level roles.
- Route53 credentials used for DNS-01 live in a Kubernetes secret local to the ingress namespace (`deps/ingress_tls/main.tf:173`). Rotate the AWS access keys periodically and reapply to refresh the secret.

## Out of scope today
- Azure and GCP managed services are placeholders; no Terraform resources exist yet for those clouds, but the provider mode files are ready for upcoming implementations.
- Web application firewalls, runtime security agents, and centralized SIEM integrations are not provisioned here. Layer them on through your cloud platform or Kubernetes tooling.
- Compliance artefacts and policy-as-code checks are outside this repository—run them separately during CI/CD.
