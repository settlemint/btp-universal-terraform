# Azure mode: Deploy PostgreSQL via Azure Database for PostgreSQL
# TODO: Implement Azure Database for PostgreSQL

# Placeholder for Azure implementation
# resource "azurerm_postgresql_flexible_server" "postgres" {
#   count               = var.mode == "azure" ? 1 : 0
#   name                = var.azure.server_name
#   resource_group_name = var.azure.resource_group_name
#   location            = var.azure.location
#   version             = var.azure.version
#   sku_name            = var.azure.sku_name
#   storage_mb          = var.azure.storage_mb
#   administrator_login = var.azure.admin_username
#   administrator_password = var.azure.admin_password
# }

locals {
  azure_host     = var.mode == "azure" ? "postgres-server.postgres.database.azure.com" : null
  azure_port     = var.mode == "azure" ? 5432 : null
  azure_user     = var.mode == "azure" ? var.azure.admin_username : null
  azure_password = var.mode == "azure" ? var.azure.admin_password : null
  azure_database = var.mode == "azure" ? var.azure.database : null
}
