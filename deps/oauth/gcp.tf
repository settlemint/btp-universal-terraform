# GCP mode: GCP Identity Platform
# TODO: Implement GCP Identity Platform configuration

# Placeholder for GCP Identity Platform
# resource "google_identity_platform_config" "config" {
#   count   = var.mode == "gcp" ? 1 : 0
#   project = var.gcp.project_id
# }

locals {
  gcp_issuer        = var.mode == "gcp" ? "https://securetoken.google.com/${var.gcp.project_id}" : null
  gcp_admin_url     = var.mode == "gcp" ? "https://console.cloud.google.com/customer-identity" : null
  gcp_client_id     = var.mode == "gcp" ? var.gcp.client_id : null
  gcp_client_secret = var.mode == "gcp" ? var.gcp.client_secret : null
  gcp_scopes        = var.mode == "gcp" ? ["openid", "email", "profile"] : null
  gcp_callback_urls = var.mode == "gcp" ? var.gcp.callback_urls : null
}
