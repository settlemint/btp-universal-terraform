# GCP mode: GCP Secret Manager integration
# TODO: Implement GCP Secret Manager integration

# Placeholder for GCP Secret Manager
# GCP Secret Manager is typically accessed via service account credentials
# This module could provide centralized project/secret paths if needed

locals {
  gcp_vault_addr = var.mode == "gcp" ? null : null  # Not applicable
  gcp_token      = var.mode == "gcp" ? null : null  # Service Account-based
  gcp_kv_mount   = var.mode == "gcp" ? null : null
  gcp_paths      = var.mode == "gcp" ? [] : null
}
