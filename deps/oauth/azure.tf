# Azure mode: Azure AD App Registration for OAuth

# Get current client configuration
data "azuread_client_config" "current" {
  count = var.mode == "azure" ? 1 : 0
}

locals {
  # Extract context
  azure_oauth_tenant_id = var.mode == "azure" && try(var.azure.tenant_id, null) != null ? var.azure.tenant_id : (var.mode == "azure" ? data.azuread_client_config.current[0].tenant_id : null)
}

# Azure AD Application
resource "azuread_application" "oauth" {
  count        = var.mode == "azure" ? 1 : 0
  display_name = try(var.azure.app_name, "BTP Platform")
  owners       = [data.azuread_client_config.current[0].object_id]

  # Web platform for OAuth callback
  web {
    redirect_uris = try(var.azure.callback_urls, ["https://localhost/auth/callback"])

    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }

  # API permissions
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }

    resource_access {
      id   = "64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0" # email
      type = "Scope"
    }

    resource_access {
      id   = "14dad69e-099b-42c9-810b-d002981feec1" # profile
      type = "Scope"
    }

    resource_access {
      id   = "37f7f235-527c-4136-accd-4a02d197296e" # openid
      type = "Scope"
    }
  }

  # Optional API exposure
  dynamic "api" {
    for_each = try(var.azure.expose_api, false) ? [1] : []
    content {
      requested_access_token_version = 2
    }
  }

  tags = [
    "terraform",
    "btp-oauth"
  ]
}

# Service Principal for the application
resource "azuread_service_principal" "oauth" {
  count          = var.mode == "azure" ? 1 : 0
  application_id = azuread_application.oauth[0].application_id
  owners         = [data.azuread_client_config.current[0].object_id]

  tags = [
    "terraform",
    "btp-oauth"
  ]
}

# Application Password (Client Secret)
resource "azuread_application_password" "oauth" {
  count                 = var.mode == "azure" && try(var.azure.generate_client_secret, true) ? 1 : 0
  application_object_id = azuread_application.oauth[0].object_id
  display_name          = "BTP OAuth Secret"
  end_date_relative     = try(var.azure.client_secret_expiry, "8760h") # 1 year default
}

# Outputs
locals {
  # OIDC issuer URL
  azure_issuer = var.mode == "azure" ? "https://login.microsoftonline.com/${local.azure_oauth_tenant_id}/v2.0" : null

  # Azure Portal URL for admin
  azure_admin_url = var.mode == "azure" ? "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Overview/appId/${azuread_application.oauth[0].application_id}" : null

  # Client credentials
  azure_client_id = var.mode == "azure" && length(azuread_application.oauth) > 0 ? azuread_application.oauth[0].application_id : null

  azure_client_secret = var.mode == "azure" && length(azuread_application_password.oauth) > 0 ? azuread_application_password.oauth[0].value : (
    try(var.azure.client_secret, null)
  )

  # OAuth scopes
  azure_scopes = var.mode == "azure" ? ["openid", "profile", "email"] : null

  # Callback URLs
  azure_callback_urls = var.mode == "azure" ? try(var.azure.callback_urls, []) : null

  # Tenant ID
  azure_tenant_id_oauth = var.mode == "azure" ? local.azure_oauth_tenant_id : null

  # Well-known endpoints
  azure_authorization_endpoint = var.mode == "azure" ? "https://login.microsoftonline.com/${local.azure_oauth_tenant_id}/oauth2/v2.0/authorize" : null
  azure_token_endpoint         = var.mode == "azure" ? "https://login.microsoftonline.com/${local.azure_oauth_tenant_id}/oauth2/v2.0/token" : null
  azure_userinfo_endpoint      = var.mode == "azure" ? "https://graph.microsoft.com/oidc/userinfo" : null
}
