# Azure mode: Deploy PostgreSQL via Azure Database for PostgreSQL Flexible Server

locals {
  # Extract networking context
  azure_postgres_rg       = try(var.azure.resource_group_name, var.azure_network.resource_group_name, "btp-resources")
  azure_postgres_location = try(var.azure.location, var.azure_network.location, "eastus")
  azure_postgres_subnet   = try(var.azure.delegated_subnet_id, var.azure_network.subnet_id, null)
  azure_postgres_vnet_id  = try(var.azure_network.vnet_id, null)
}

# Private DNS Zone for PostgreSQL
resource "azurerm_private_dns_zone" "postgres" {
  count               = var.mode == "azure" ? 1 : 0
  name                = "${var.azure.server_name}.private.postgres.database.azure.com"
  resource_group_name = local.azure_postgres_rg

  tags = {
    ManagedBy   = "terraform"
    Application = "btp-postgres"
  }
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  count                 = var.mode == "azure" && local.azure_postgres_vnet_id != null ? 1 : 0
  name                  = "${var.azure.server_name}-vnet-link"
  resource_group_name   = local.azure_postgres_rg
  private_dns_zone_name = azurerm_private_dns_zone.postgres[0].name
  virtual_network_id    = local.azure_postgres_vnet_id

  tags = {
    ManagedBy   = "terraform"
    Application = "btp-postgres"
  }
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "postgres" {
  count               = var.mode == "azure" ? 1 : 0
  name                = var.azure.server_name
  resource_group_name = local.azure_postgres_rg
  location            = local.azure_postgres_location
  version             = var.azure.version
  sku_name            = var.azure.sku_name
  storage_mb          = var.azure.storage_mb

  administrator_login    = var.azure.admin_username
  administrator_password = try(var.secrets.password, var.azure.admin_password)

  # VNet integration
  delegated_subnet_id = local.azure_postgres_subnet
  private_dns_zone_id = azurerm_private_dns_zone.postgres[0].id

  # Backup configuration
  backup_retention_days        = try(var.azure.backup_retention_days, 7)
  geo_redundant_backup_enabled = try(var.azure.geo_redundant_backup, false)

  # High Availability
  dynamic "high_availability" {
    for_each = try(var.azure.high_availability_enabled, false) ? [1] : []
    content {
      mode                      = "ZoneRedundant"
      standby_availability_zone = try(var.azure.standby_availability_zone, "2")
    }
  }

  # Maintenance window
  dynamic "maintenance_window" {
    for_each = try(var.azure.maintenance_window, null) != null ? [1] : []
    content {
      day_of_week  = try(var.azure.maintenance_window.day_of_week, 0)
      start_hour   = try(var.azure.maintenance_window.start_hour, 3)
      start_minute = try(var.azure.maintenance_window.start_minute, 0)
    }
  }

  tags = {
    Name        = var.azure.server_name
    ManagedBy   = "terraform"
    Application = "btp-postgres"
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

# PostgreSQL Database
resource "azurerm_postgresql_flexible_server_database" "database" {
  count     = var.mode == "azure" ? 1 : 0
  name      = var.azure.database
  server_id = azurerm_postgresql_flexible_server.postgres[0].id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# PostgreSQL Configuration (optional tuning)
resource "azurerm_postgresql_flexible_server_configuration" "max_connections" {
  count     = var.mode == "azure" ? 1 : 0
  name      = "max_connections"
  server_id = azurerm_postgresql_flexible_server.postgres[0].id
  value     = try(var.azure.max_connections, "100")
}

resource "azurerm_postgresql_flexible_server_configuration" "ssl_enforcement" {
  count     = var.mode == "azure" ? 1 : 0
  name      = "require_secure_transport"
  server_id = azurerm_postgresql_flexible_server.postgres[0].id
  value     = try(var.azure.require_ssl, "on")
}

# Firewall rules (if public access is enabled for testing)
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure" {
  count            = var.mode == "azure" && try(var.azure.allow_azure_services, false) ? 1 : 0
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.postgres[0].id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Outputs
locals {
  azure_host = var.mode == "azure" && length(azurerm_postgresql_flexible_server.postgres) > 0 ? azurerm_postgresql_flexible_server.postgres[0].fqdn : null
  azure_port = var.mode == "azure" ? 5432 : null
  azure_user = var.mode == "azure" ? var.azure.admin_username : null
  azure_password = var.mode == "azure" ? try(var.secrets.password, var.azure.admin_password) : null
  azure_database = var.mode == "azure" ? var.azure.database : null

  # Connection string
  azure_connection_string = var.mode == "azure" && local.azure_host != null ? "postgresql://${local.azure_user}:${local.azure_password}@${local.azure_host}:${local.azure_port}/${local.azure_database}?sslmode=require" : null
}
