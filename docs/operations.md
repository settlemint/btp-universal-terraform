# Operations Guide

These tasks help you keep environments healthy after `terraform apply`. All commands assume you are running from the repository root.

## Verify a deployment
- `terraform output post_deploy_message` prints the key endpoints that the stack creates (`outputs.tf:61`). Reach the platform URL and Grafana dashboard first, then confirm Postgres/Redis connectivity if the application team needs them.
- For scripted checks, use `terraform output -json post_deploy_urls` to parse individual URLs, hostnames, and credentials.
- When Terraform created the cluster (`k8s_cluster.mode = "aws"`), write the kubeconfig to disk:
  ```bash
  terraform output -json k8s_cluster | jq -r '.value.kubeconfig' > kubeconfig.yaml
  KUBECONFIG=$PWD/kubeconfig.yaml kubectl get nodes
  ```
  For BYO clusters, fall back to the kubeconfig you already manage.

## Rotating credentials
- Rotate secrets in their source system, then rerun `terraform apply` so dependent Helm releases pick up the changes. Examples:
  - Vault dev mode (`secrets.k8s.dev_mode = true`) stores the root token locally—switch it off and provide storage configuration in `secrets.k8s.values` before promoting.
  - AWS Secrets Manager is not wired yet; pass new values through `TF_VAR_*` variables or BYO secrets and reapply.
  - Grafana admin password comes from `TF_VAR_grafana_admin_password`. Changing the value and running `terraform apply` forces Helm to update the secret.

## Dependency maintenance
- Managed AWS services expose maintenance settings through the dependency config blocks (e.g., `postgres.aws.maintenance_window`, `redis.aws.snapshot_retention_limit`). Adjust them in tfvars, run `terraform plan`, and apply.
- Kubernetes mode dependencies ship without persistent volumes by default. If you need data retention, override the Helm values via the `values` map in each dependency block (for example, enable PVCs in `postgres.k8s.values`).
- When mixing managed and k8s modes, ensure security groups and namespaces remain aligned. Terraform only creates namespaces when `manage_namespace = true` on the module.

## Cleaning up
- Always destroy dependencies before tearing down the VPC. Running `terraform destroy -var-file <profile>.tfvars` cleans resources in the safe order defined in `main.tf`.
- If AWS managed clusters are in use, the `null_resource.cleanup_k8s_loadbalancers` hook (`main.tf:101`) deletes Kubernetes `LoadBalancer` services during destroy to avoid orphaned ENIs. Verify that no extra load balancers remain if you have out-of-band services in the cluster.
