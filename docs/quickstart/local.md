# Quickstart — Local Cluster

Time to complete: ~10–15 minutes

What you’ll do
- Spin up all dependencies as Helm charts inside a local cluster and deploy BTP
- Verify ingress, dashboards, and credentials from Terraform outputs

Prerequisites
- OrbStack, kind, or minikube
- `kubectl` and `helm`
- Terraform 1.6+

1) Preflight ✅
```bash
./scripts/preflight.sh
```
Confirms: Helm repos, cluster connectivity, default storage class

2) Plan & apply 🧪
```bash
terraform init
terraform plan -var-file examples/generic-orbstack-dev.tfvars
terraform apply -var-file examples/generic-orbstack-dev.tfvars
```

What gets installed
- Ingress NGINX + cert-manager (self-signed issuer)
- Postgres (Zalando), Redis (Bitnami), MinIO, Keycloak, Vault (dev)
- kube-prometheus-stack, Loki; BTP Helm release wired to outputs

3) Verify 🔎
```bash
kubectl get pods -A | egrep "ingress|cert|postgres|redis|minio|keycloak|vault|grafana|prom|loki|settlemint"
kubectl get ing -A

# Keycloak admin (default realm)
open http://keycloak.127.0.0.1.nip.io || echo "Open in browser"

# Grafana
terraform output -json metrics_logs | jq -r .grafana_url

# MinIO (if console enabled via values)
open http://minio-console.127.0.0.1.nip.io || true
```

Outputs to note
- Postgres connection string; Redis password; MinIO access/secret
- Keycloak issuer/admin URL; Grafana URL and admin credentials

Cleanup 🧹
```bash
terraform destroy -var-file examples/generic-orbstack-dev.tfvars
```

Stuck?
- See docs/operations/troubleshooting.md for fast fixes

Architecture view
- Kubernetes only (all k8s): docs/architecture/k8s-full.md
