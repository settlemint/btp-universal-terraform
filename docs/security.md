# Security

**Security controls currently implemented in Terraform modules.**

## Ingress and certificates

**TLS termination** via cert-manager (deps/ingress_tls/main.tf:63)
- HTTP-01 challenges by default
- DNS-01 via Route53 when configured

**Enable DNS-01 automation**
- Set `ingress_tls.k8s.route53_credentials_secret_name`
- Export `TF_VAR_aws_access_key_id` and `TF_VAR_aws_secret_access_key`
- See AWS access key variables in variables.tf

**Ingress controller service exposure**
- Configured in tfvars (examples/aws-config.tfvars:140)
- `LoadBalancer` for cloud deployments
- Chart defaults for local clusters
- Check `ingress_tls.k8s.values_nginx` in your profile

**Wildcard certificates** are optional
- Provisioned when DNS module returns wildcard hostnames (main.tf:63)
- Otherwise cert-manager issues per-ingress certificates

## Data stores

**RDS Postgres** (deps/postgres/aws.tf:57)
- Encryption at rest enabled
- Automated backups enabled
- Multi-AZ by default

**ElastiCache Redis** (deps/redis/aws.tf:45)
- Transit encryption available
- At-rest encryption available
- Enable `transit_encryption_enabled` and provide auth token for TLS clients
- Without TLS, Redis listens in plaintext inside VPC

**S3 Object Storage** (deps/object_storage/aws.tf:46)
- Server-side encryption enabled
- Public access blocked
- For existing buckets, verify these settings manually

**Kubernetes mode dependencies**
- Deploy Helm charts with in-cluster services
- Default: non-persistent storage
- Add persistence and network policies via `values` overrides

## Secrets and credentials

**Vault in k8s mode** (deps/secrets/k8s.tf:19)
- Runs in dev mode by default
- Switch `secrets.k8s.dev_mode = false` for production
- Configure persistent storage before production use

**Terraform never writes secrets to disk**
- All sensitive inputs from variables.tf "Credentials and secret inputs"
- Use `TF_VAR_*` environment variables
- Or integrate with Terraform Cloud secret manager

**OAuth managed mode (Cognito)**
- Provisions user pool and client
- Rotation and MFA policies managed by operator
- Document requirements in examples/aws-config.tfvars

## IAM and networking

**AWS security groups** (cloud/aws/main.tf:152)
- Postgres and Redis restricted to VPC CIDR
- Additional groups can be listed in configuration
- Review rules when connecting from outside VPC

**EKS IAM roles** (deps/k8s_cluster/aws.tf:24)
- Standard AWS-managed policies attached
- For workload AWS API access, add custom policies via IRSA
- Terraform creates only cluster-level roles

**Route53 credentials for DNS-01** (deps/ingress_tls/main.tf:173)
- Stored in Kubernetes secret in ingress namespace
- Rotate AWS access keys periodically and reapply

## Out of scope

**Azure and GCP managed services** are placeholders
- No Terraform resources exist yet
- Provider mode files ready for future implementation

**Additional security tooling not included**
- Web application firewalls
- Runtime security agents
- Centralized SIEM integrations
- Layer these on through cloud platform or Kubernetes tooling

**Compliance artifacts**
- Policy-as-code checks
- Run separately during CI/CD
- Not part of this repository
