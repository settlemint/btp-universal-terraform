# Azure mode: Azure AD B2C
# TODO: Implement Azure AD B2C tenant

# Placeholder for Azure AD B2C implementation
# resource "azurerm_aadb2c_directory" "b2c" {
#   count               = var.mode == "azure" ? 1 : 0
#   resource_group_name = var.azure.resource_group_name
#   data_residency_location = var.azure.location
#   display_name        = var.azure.tenant_name
#   domain_name         = var.azure.domain_name
#   sku_name            = var.azure.sku_name
# }

locals {
  azure_issuer        = var.mode == "azure" ? "https://${var.azure.tenant_name}.b2clogin.com/${var.azure.tenant_id}/v2.0/" : null
  azure_admin_url     = var.mode == "azure" ? "https://portal.azure.com" : null
  azure_client_id     = var.mode == "azure" ? var.azure.client_id : null
  azure_client_secret = var.mode == "azure" ? var.azure.client_secret : null
  azure_scopes        = var.mode == "azure" ? ["openid", "profile", "email"] : null
  azure_callback_urls = var.mode == "azure" ? var.azure.callback_urls : null
}
