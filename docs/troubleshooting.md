# Troubleshooting

**Common issues and solutions when Terraform or the installer appears stuck.**

## Terraform runs

**Enable debug logging**
```bash
TF_LOG=INFO terraform plan -var-file <profile>.tfvars
```

This surfaces provider errors that may have scrolled past.

**Check required environment variables**
```bash
env | grep TF_VAR_
```

Missing `TF_VAR_*` secrets cause resources to wait on credentials. See variables.tf for required inputs.

## Kubernetes cluster

**Check pod status**
```bash
kubectl get pods -n btp-deps
kubectl describe pod/<pod-name> -n btp-deps
```

**Common issues**
- **Storage classes** – Ensure compatible StorageClass exists if persistence enabled
- **Ingress classes** – Verify ingress class matches cluster configuration
- **Image pull permissions** – Check service accounts have registry access

**Validate StorageClass** (when persistence enabled)
```bash
kubectl get storageclass
```

**Inspect services expecting external endpoints**
```bash
kubectl get svc -n btp-deps
```

For cloud clusters expecting load balancers:
- Verify service type aligns with provider
- Ensure controller reconciles the object

## AWS managed dependencies

**Verify subnet and security group IDs**
- Check values passed to Postgres/Redis/Object Storage
- Terraform creates subnet groups only when `*_manage_subnet_group = true`
- Otherwise requires existing subnet group names

**Check AWS console for failed operations**
- RDS and ElastiCache emit detailed events
- Look for parameter value errors or networking issues

**Common AWS errors**
- Invalid CIDR ranges in security groups
- Subnet groups in wrong availability zones
- Missing IAM permissions for resource creation

## DNS and TLS

**Certificates not issuing**

**Check Route53 credentials** (for DNS-01)
```bash
kubectl get secret -n <ingress-namespace>
```

Credentials must be present (deps/ingress_tls/main.tf:173).

**Switch to HTTP-01 for local clusters**
- Remove Route53 configuration
- cert-manager will use HTTP-01 challenges

**Debug certificate issues**
```bash
kubectl describe certificate <cert-name>
kubectl describe order <order-name>
```

Look for:
- Missing DNS records
- Solver configuration mismatches
- ACME rate limits (use staging environment)
