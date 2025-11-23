# Azure mode: Deploy Redis via Azure Cache for Redis

locals {
  # Extract networking context
  azure_redis_rg       = try(var.azure.resource_group_name, var.azure_network.resource_group_name, "btp-resources")
  azure_redis_location = try(var.azure.location, var.azure_network.location, "eastus")
  azure_redis_subnet   = try(var.azure.subnet_id, var.azure_network.subnet_id, null)
}

# Azure Cache for Redis
resource "azurerm_redis_cache" "redis" {
  count               = var.mode == "azure" ? 1 : 0
  name                = var.azure.cache_name
  location            = local.azure_redis_location
  resource_group_name = local.azure_redis_rg
  capacity            = var.azure.capacity
  family              = var.azure.family
  sku_name            = var.azure.sku_name

  # SSL Configuration
  enable_non_ssl_port = !try(var.azure.ssl_enabled, true)
  minimum_tls_version = try(var.azure.minimum_tls_version, "1.2")

  # Redis Configuration
  redis_configuration {
    enable_authentication           = try(var.azure.enable_authentication, true)
    maxmemory_reserved              = try(var.azure.maxmemory_reserved, null)
    maxmemory_delta                 = try(var.azure.maxmemory_delta, null)
    maxmemory_policy                = try(var.azure.maxmemory_policy, "volatile-lru")
    maxfragmentationmemory_reserved = try(var.azure.maxfragmentationmemory_reserved, null)

    # Persistence (Premium tier only)
    dynamic "rdb_backup_enabled" {
      for_each = var.azure.sku_name == "Premium" && try(var.azure.rdb_backup_enabled, false) ? [1] : []
      content {
        rdb_backup_enabled            = true
        rdb_backup_frequency          = try(var.azure.rdb_backup_frequency, 60)
        rdb_backup_max_snapshot_count = try(var.azure.rdb_backup_max_snapshot_count, 1)
        rdb_storage_connection_string = try(var.azure.rdb_storage_connection_string, null)
      }
    }
  }

  # Private endpoint for Premium tier (VNet integration)
  dynamic "private_static_ip_address" {
    for_each = var.azure.sku_name == "Premium" && local.azure_redis_subnet != null ? [1] : []
    content {
      subnet_id = local.azure_redis_subnet
    }
  }

  # Patch schedule
  dynamic "patch_schedule" {
    for_each = try(var.azure.patch_schedule, null) != null ? [var.azure.patch_schedule] : []
    content {
      day_of_week    = patch_schedule.value.day_of_week
      start_hour_utc = patch_schedule.value.start_hour_utc
    }
  }

  # Zones for zone-redundant deployments (Premium tier)
  zones = var.azure.sku_name == "Premium" ? try(var.azure.zones, null) : null

  tags = {
    Name        = var.azure.cache_name
    ManagedBy   = "terraform"
    Application = "btp-redis"
  }
}

# Firewall rules (if needed)
resource "azurerm_redis_firewall_rule" "allow_subnet" {
  count               = var.mode == "azure" && try(var.azure.firewall_rules, null) != null ? length(var.azure.firewall_rules) : 0
  name                = var.azure.firewall_rules[count.index].name
  redis_cache_name    = azurerm_redis_cache.redis[0].name
  resource_group_name = local.azure_redis_rg
  start_ip            = var.azure.firewall_rules[count.index].start_ip
  end_ip              = var.azure.firewall_rules[count.index].end_ip
}

# Outputs
locals {
  azure_host = var.mode == "azure" && length(azurerm_redis_cache.redis) > 0 ? azurerm_redis_cache.redis[0].hostname : null

  # Port depends on SSL configuration
  azure_port = var.mode == "azure" ? (
    try(var.azure.ssl_enabled, true) ? 6380 : 6379
  ) : null

  # Primary access key as password
  azure_password = var.mode == "azure" && length(azurerm_redis_cache.redis) > 0 ? azurerm_redis_cache.redis[0].primary_access_key : null

  # Scheme for connection URL
  azure_scheme = var.mode == "azure" ? (
    try(var.azure.ssl_enabled, true) ? "rediss" : "redis"
  ) : null

  azure_tls_enabled = var.mode == "azure" ? try(var.azure.ssl_enabled, true) : null

  # Connection string
  azure_connection_string = var.mode == "azure" && local.azure_host != null ? "${local.azure_scheme}://:${local.azure_password}@${local.azure_host}:${local.azure_port}" : null
}
