# AWS Provider

**AWS has complete managed support for Postgres, Redis, Object Storage, and OAuth.**

## Managed services available

The `cloud/aws` module provisions:
- **Networking** – VPC, subnets, security groups, IAM roles
- **Postgres** – RDS with Multi-AZ, encryption, automated backups
- **Redis** – ElastiCache replication group with TLS
- **Object Storage** – S3 buckets with versioning and encryption
- **OAuth** – Cognito user pools and app clients

**Other dependencies** (ingress, secrets, metrics/logs) run in Kubernetes mode.

## Prerequisites

**IAM permissions for**
- VPC, EC2, IAM
- RDS, ElastiCache, S3
- Cognito, Route53

**Optional**
- Route53 hosted zone for custom domains
- S3 + DynamoDB for remote state backend

## Service defaults

**RDS Postgres**
- Multi-AZ with deletion protection
- gp3 100 GiB storage (auto-scales to 200 GiB)
- Daily backups (14 day retention)
- Performance Insights enabled
- Final snapshot on destroy

Override in the dependency `config` block for dev environments.

**ElastiCache Redis**
- Replication group with TLS
- Transit encryption enabled when subnet group supports it

**Cognito OAuth**
- User pool and app client created
- Set `callback_urls` to match your BTP hostname

**S3 Object Storage**
- Versioning enabled
- Server-side encryption (SSE-S3)
- Public access blocked
- Can use existing bucket

**Ingress and TLS**
- ingress-nginx + cert-manager installed in Kubernetes
- Provide AWS credentials and Route53 zone ID for DNS-01 automation

## Using Kubernetes mode with AWS

**Helm charts run inside your EKS cluster**
- Ensure sufficient capacity and storage classes supporting ReadWriteOnce
- Security groups from `cloud/aws` can be reused by AWS Load Balancer Controller

**For ingress**, security groups allow traffic from the VPC CIDR and any additional groups you configure.

## Bring-your-own endpoints

**Supply existing AWS resources**
- Provide endpoints via dependency `config.endpoint` blocks
- Include TLS certificates or CA bundles for verification
- Store credentials in AWS Secrets Manager and reference ARNs (avoid committing passwords)
