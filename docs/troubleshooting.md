# Troubleshooting

When Terraform or the installer appears stuck, inspect the cluster and supporting services before changing configuration.

## Terraform run
- Re-run `terraform plan` with `TF_LOG=INFO` to surface provider errors that may have scrolled past during the first apply.
- Confirm required `TF_VAR_*` secrets are loaded; missing inputs often result in resources waiting on credentials (see `variables.tf`).

## Kubernetes cluster
- Check pod status: `kubectl get pods -n btp-deps` and `kubectl describe pod/<name>`. Most install issues stem from storage classes, ingress classes, or image pull permissions not matching the cluster.
- Validate that a compatible StorageClass exists if you enabled persistence in any dependency Helm values.
- Inspect services that expect external endpoints (for example, `kubectl get svc -n btp-deps`). If the cluster should provision a load balancer, make sure the service type aligns with the provider and that the controller reconciles the object.

## Managed cloud dependencies
- For AWS, verify subnet and security group IDs passed to Postgres/Redis/Object Storage are correct. Terraform creates subnet groups only when `*_manage_subnet_group = true`; otherwise it requires existing names.
- Check the AWS console for failed create/update operations—RDS and ElastiCache emit detailed events when parameter values or networking are invalid.

## DNS and TLS
- If certificates do not issue, confirm Route53 credentials are present in the ingress namespace (`deps/ingress_tls/main.tf:173`) or switch to HTTP-01 challenges for local clusters.
- Use `kubectl describe certificate` and `kubectl describe order` (cert-manager CRDs) to identify missing DNS records or solver configuration mismatches.
