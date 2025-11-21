# GCP mode: GCP Secret Manager integration
# GCP Secret Manager is accessed via service account credentials and Workload Identity
# This provides metadata for applications to access secrets

locals {
  # GCP uses Secret Manager API with service account auth, not Vault-style endpoints
  gcp_vault_addr = var.mode == "gcp" ? null : null # Not applicable - uses Secret Manager API
  gcp_token      = var.mode == "gcp" ? null : null # Service Account/Workload Identity based
  gcp_kv_mount   = var.mode == "gcp" ? null : null # Not applicable - uses project/secret paths
  gcp_paths      = var.mode == "gcp" ? [] : null   # Not applicable - secrets are project-scoped
}
