# Azure — Minimum Permissions (Guidance)

Use least-privilege roles or custom roles scoped to the resource group/subscription used by Terraform:

- AKS: `Azure Kubernetes Service Contributor` (for cluster ops if provisioned)
- Network: `Network Contributor` (vNet, LB, App Gateway)
- Key Vault: `Key Vault Administrator` (for automation) or split roles for cert/secret ops
- Storage: `Storage Blob Data Owner` for blob containers/buckets
- PostgreSQL Flexible Server: `Contributor` over PG resources
- Cache for Redis: `Contributor` over Redis resources
- Log Analytics + Managed Grafana: `Monitoring Contributor` (and Grafana roles)

Recommendation
- Use Entra Workload Identity with AKS; prefer Private Endpoints for PaaS services; scope roles to resource groups per environment.

