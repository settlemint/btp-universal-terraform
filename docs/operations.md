# Operations

**Day-2 tasks to keep environments healthy after deployment.**

## Verify deployment

**View key endpoints**
```bash
terraform output post_deploy_message
```

**Get all service URLs and credentials (JSON)**
```bash
terraform output -json post_deploy_urls
```

**Export kubeconfig** (when Terraform creates the cluster)
```bash
terraform output -json k8s_cluster | jq -r '.value.kubeconfig' > kubeconfig.yaml
export KUBECONFIG=$PWD/kubeconfig.yaml
kubectl get nodes
```

**Check specific services**
- Platform URL – Main application endpoint
- Grafana dashboard – Metrics and monitoring
- Postgres/Redis connectivity – If needed by application team

## Rotate credentials

**Rotate in source system, then reapply**
```bash
terraform apply -var-file <profile>.tfvars
```

Dependent Helm releases pick up the changes automatically.

**Vault dev mode** (`secrets.k8s.dev_mode = true`)
- Stores root token locally
- Switch to `dev_mode = false` for production
- Configure storage backend via `secrets.k8s.values`

**AWS Secrets Manager**
- Not yet wired to Terraform
- Pass new values via `TF_VAR_*` environment variables

**Grafana admin password**
```bash
export TF_VAR_grafana_admin_password=new_password
terraform apply -var-file <profile>.tfvars
```

## Maintain dependencies

**AWS managed services**
- Adjust maintenance windows in dependency config blocks
  - `postgres.aws.maintenance_window`
  - `redis.aws.snapshot_retention_limit`
- Run `terraform plan` and apply

**Kubernetes mode dependencies**
- Default: no persistent volumes
- Enable data retention by overriding Helm values
  ```bash
  postgres.k8s.values = {
    persistence = {
      enabled = true
      size = "20Gi"
    }
  }
  ```

**When mixing modes**, ensure security groups and namespaces align
- Terraform creates namespaces only when `manage_namespace = true`

## Clean up

**Destroy in safe order**
```bash
terraform destroy -var-file <profile>.tfvars
```

**Before destroying AWS VPC**
- Terraform destroys dependencies first (defined in main.tf)

**AWS managed clusters with LoadBalancer services**
- `null_resource.cleanup_k8s_loadbalancers` (main.tf:101) deletes Kubernetes LoadBalancer services
- Prevents orphaned ENIs
- Verify no extra load balancers remain if you have out-of-band services
