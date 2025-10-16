# GCP mode: Deploy GCS bucket
# TODO: Implement GCP Cloud Storage bucket

# Placeholder for GCP Cloud Storage implementation
# resource "google_storage_bucket" "bucket" {
#   count    = var.mode == "gcp" ? 1 : 0
#   name     = var.gcp.bucket_name
#   location = var.gcp.location
#   storage_class = var.gcp.storage_class
#
#   uniform_bucket_level_access = true
# }

locals {
  gcp_endpoint       = var.mode == "gcp" ? "https://storage.googleapis.com" : null
  gcp_bucket         = var.mode == "gcp" ? var.gcp.bucket_name : null
  gcp_access_key     = var.mode == "gcp" ? var.gcp.access_key : null
  gcp_secret_key     = var.mode == "gcp" ? var.gcp.secret_key : null
  gcp_region         = var.mode == "gcp" ? var.gcp.location : null
  gcp_use_path_style = var.mode == "gcp" ? false : null
}
