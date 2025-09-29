# Cloud — AWS

Summary
- AWS mapping for network, identity, Kubernetes (EKS), and managed services: RDS, ElastiCache, S3, Cognito, Secrets Manager, ALB/ACM, CloudWatch/AMP/AMG.

Modes at a glance
- managed: Provision AWS-native resources and export unified outputs
- k8s: Deploy Helm charts into EKS
- byo: Consume pre-existing endpoints/credentials

Architecture notes
- Prefer private subnets/endpoints; ACM for certs; ALB Ingress Controller for ingress
- Use IAM Roles for Service Accounts (IRSA) for in-cluster AWS access

Example profile (all managed)
```hcl
platform = "aws"
postgres = { mode = "managed", managed = { provider = "aws", instance_class = "db.t3.medium" } }
redis    = { mode = "managed", managed = { provider = "aws", node_type = "cache.t4g.small" } }
object_storage = { mode = "managed", managed = { provider = "aws", bucket = "btp-artifacts" } }
oauth    = { mode = "managed", managed = { provider = "aws", app_client_name = "btp" } }
secrets  = { mode = "managed", managed = { provider = "aws", engine = "secrets_manager" } }
ingress_tls = { mode = "managed", managed = { provider = "aws", certificate_arn = "..." } }
metrics_logs = { mode = "managed", managed = { provider = "aws", amp = true } }
```

Verification
- Check Route53/ALB endpoints and issued ACM certificates; validate app health

Security & gotchas
- Scope IAM narrowly for prod; enable encryption and backups by default

See also
- IAM reference: docs/reference/iam/aws.md
