# Azure mode: Deploy Azure Blob Storage
# TODO: Implement Azure Blob Storage with container

# Placeholder for Azure Blob Storage implementation
# resource "azurerm_storage_account" "storage" {
#   count                    = var.mode == "azure" ? 1 : 0
#   name                     = var.azure.storage_account_name
#   resource_group_name      = var.azure.resource_group_name
#   location                 = var.azure.location
#   account_tier             = var.azure.account_tier
#   account_replication_type = var.azure.replication_type
# }
#
# resource "azurerm_storage_container" "container" {
#   count                 = var.mode == "azure" ? 1 : 0
#   name                  = var.azure.container_name
#   storage_account_name  = azurerm_storage_account.storage[0].name
#   container_access_type = "private"
# }

locals {
  azure_endpoint       = var.mode == "azure" ? "https://${var.azure.storage_account_name}.blob.core.windows.net" : null
  azure_bucket         = var.mode == "azure" ? var.azure.container_name : null
  azure_access_key     = var.mode == "azure" ? var.azure.storage_account_name : null
  azure_secret_key     = var.mode == "azure" ? var.azure.access_key : null
  azure_region         = var.mode == "azure" ? var.azure.location : null
  azure_use_path_style = var.mode == "azure" ? false : null
}
