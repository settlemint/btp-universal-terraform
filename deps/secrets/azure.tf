# Azure mode: Azure Key Vault integration
# TODO: Implement Azure Key Vault integration

# Placeholder for Azure Key Vault
# resource "azurerm_key_vault" "vault" {
#   count               = var.mode == "azure" ? 1 : 0
#   name                = var.azure.key_vault_name
#   location            = var.azure.location
#   resource_group_name = var.azure.resource_group_name
#   tenant_id           = var.azure.tenant_id
#   sku_name            = var.azure.sku_name
# }

locals {
  azure_vault_addr = var.mode == "azure" ? "https://${var.azure.key_vault_name}.vault.azure.net" : null
  azure_token      = var.mode == "azure" ? null : null # Managed Identity / Service Principal
  azure_kv_mount   = var.mode == "azure" ? null : null
  azure_paths      = var.mode == "azure" ? [] : null
}
