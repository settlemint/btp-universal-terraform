# Azure mode: Deploy Redis via Azure Cache for Redis
# TODO: Implement Azure Cache for Redis

# Placeholder for Azure implementation
# resource "azurerm_redis_cache" "redis" {
#   count               = var.mode == "azure" ? 1 : 0
#   name                = var.azure.cache_name
#   location            = var.azure.location
#   resource_group_name = var.azure.resource_group_name
#   capacity            = var.azure.capacity
#   family              = var.azure.family
#   sku_name            = var.azure.sku_name
#   enable_non_ssl_port = !var.azure.ssl_enabled
# }

locals {
  azure_host        = var.mode == "azure" ? "redis-cache.redis.cache.windows.net" : null
  azure_port        = var.mode == "azure" ? (var.azure.ssl_enabled ? 6380 : 6379) : null
  azure_password    = var.mode == "azure" ? var.azure.primary_access_key : null
  azure_scheme      = var.mode == "azure" ? (var.azure.ssl_enabled ? "rediss" : "redis") : null
  azure_tls_enabled = var.mode == "azure" ? var.azure.ssl_enabled : null
}
