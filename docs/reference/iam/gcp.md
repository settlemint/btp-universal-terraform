# GCP — Minimum Permissions (Guidance)

Assign least-privilege roles at the project or resource level as needed:

- GKE: `roles/container.admin` (if provisioning clusters) or narrower
- Networking: `roles/compute.networkAdmin` (if managing VPC/LB)
- Cloud SQL: `roles/cloudsql.admin`
- Memorystore: `roles/redis.admin`
- GCS: `roles/storage.admin` (or `storage.objectAdmin` + bucket admin)
- Secret Manager: `roles/secretmanager.admin`
- Certificate Manager / Load Balancing: `roles/compute.loadBalancerAdmin`, `roles/certificatemanager.admin`
- Logging/Monitoring: `roles/logging.admin`, `roles/monitoring.admin` (or narrower writer/viewer + managed Prometheus roles)

Recommendation
- Use Workload Identity for in-cluster access to GCP APIs; scope Terraform service accounts to specific projects and folders per environment.

