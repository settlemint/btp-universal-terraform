# AWS — Minimum Permissions (Guidance)

Use least-privilege policies or built-in roles covering these services when using managed mode:

- EC2/VPC/ELB for networking and ALB (ingress)
- ACM for certificate issuance
- RDS for Postgres
- ElastiCache for Redis
- S3 for buckets and access keys (if needed)
- CloudWatch Logs + AMP/AMG for observability
- IAM for role creation/IRSA trust policies

Example policy snippets (summaries)
- RDS: `rds:*` on specific resources for create/update, or narrow to `CreateDBInstance`, `ModifyDBInstance`, `DeleteDBInstance`, `Describe*`.
- S3: `s3:CreateBucket`, `s3:PutBucketPolicy`, `s3:PutEncryptionConfiguration`, `s3:PutBucketVersioning`, `s3:PutLifecycleConfiguration`, `s3:Get*`, `s3:List*` on the bucket.
- ElastiCache: `elasticache:CreateCacheCluster`, `ModifyCacheCluster`, `DeleteCacheCluster`, `Describe*`.
- ACM: `acm:RequestCertificate`, `acm:DescribeCertificate`, `acm:DeleteCertificate`.
- ELBv2: `elasticloadbalancing:*` for ALB provisioning tied to specific tags.
- CloudWatch: `logs:*` for log groups; AMP/AMG API if used.

Recommendation
- Prefer Terraform execution with an admin role limited by boundary policies in non-prod; for prod, implement explicit resource-scoped policies and IAM Roles for Service Accounts (IRSA) for in-cluster access.

