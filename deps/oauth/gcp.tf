# GCP mode: Google OAuth 2.0 for authentication
# Uses Google Cloud OAuth 2.0 credentials for application authentication
# For GKE deployments, this typically uses Google OAuth consent screen and client credentials

# Note: Google Identity Platform / Firebase Auth can be enabled via console
# For most BTP deployments, we use standard Google OAuth 2.0 with client credentials

locals {
  # Google OAuth issuer for JWT tokens
  gcp_issuer = var.mode == "gcp" ? "https://accounts.google.com" : null

  # Admin console URL for managing OAuth apps
  gcp_admin_url = var.mode == "gcp" ? "https://console.cloud.google.com/apis/credentials?project=${var.gcp.project_id}" : null

  # OAuth client credentials (created manually in GCP Console or via API)
  gcp_client_id     = var.mode == "gcp" ? var.gcp.client_id : null
  gcp_client_secret = var.mode == "gcp" ? var.gcp.client_secret : null

  # Standard OAuth scopes for Google authentication
  gcp_scopes = var.mode == "gcp" ? [
    "openid",
    "email",
    "profile"
  ] : null

  # OAuth callback URLs configured for the application
  gcp_callback_urls = var.mode == "gcp" ? var.gcp.callback_urls : null
}
