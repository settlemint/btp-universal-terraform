# AWS & Kubernetes Recommendation Gaps

- [x] PostgreSQL AWS mode disables TLS (`sslmode=disable`) and skips enforcing `rds.force_ssl`, conflicting with production TLS requirements.
- [x] PostgreSQL defaults to production-ready sizing (M6g large), gp3 storage with growth headroom, multi-AZ, backups, and deletion protection; dev tfvars override these when lighter footprints are needed.
- [ ] PostgreSQL Kubernetes mode deploys a single non-HA instance with 1 Gi storage, SSL disabled, and no backup automation.
- [ ] Redis AWS mode leaves TLS, auth token, multi-node HA, and durable snapshots off by default.
- [ ] Redis Kubernetes mode disables persistence and TLS, running a single-node cache that fails production expectations.
- [ ] Object storage defaults to S3 versioning disabled, diverging from storage durability recommendations.
- [ ] AWS secrets module is an unimplemented placeholder, so Secrets Manager integration is missing.
- [ ] Vault on Kubernetes runs in dev mode with persistence disabled, violating production secret-management guidance.
- [ ] Metrics stack keeps only 24 h retention and no persistence, contrary to observability durability requirements.
- [ ] Ingress controller defaults to `NodePort` instead of a LoadBalancer per external-access best practice.
- [ ] Default tfvars and k8s example still rely on self-signed TLS issuers rather than trusted certificates.
- [ ] EKS module exposes the control plane to `0.0.0.0/0`, ignoring recommended restricted CIDR ranges.
- [ ] Node group defaults (t3.medium, minimal autoscaling) undercut documented production sizing expectations.
- [ ] VPC defaults to a single NAT gateway, leaving no AZ redundancy as advised for resilient networking.
- [ ] Keycloak deployment forces `production = false`, bundled DB, and no persistence, failing OAuth hardening guidance.
