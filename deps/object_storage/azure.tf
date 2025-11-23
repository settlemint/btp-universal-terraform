# Azure mode: Deploy Azure Blob Storage

locals {
  # Extract context
  azure_storage_rg       = try(var.azure.resource_group_name, var.azure_network.resource_group_name, "btp-resources")
  azure_storage_location = try(var.azure.location, var.azure_network.location, "eastus")

  # Generate storage account name (must be globally unique, 3-24 chars, lowercase alphanumeric)
  # Remove hyphens and limit length
  azure_storage_account_name_raw = try(var.azure.storage_account_name, "btpstorage${replace(var.base_domain, "/[^a-z0-9]/", "")}")
  azure_storage_account_name = substr(
    lower(replace(local.azure_storage_account_name_raw, "/[^a-z0-9]/", "")),
    0,
    24
  )
}

# Storage Account
resource "azurerm_storage_account" "storage" {
  count                    = var.mode == "azure" ? 1 : 0
  name                     = local.azure_storage_account_name
  resource_group_name      = local.azure_storage_rg
  location                 = local.azure_storage_location
  account_tier             = try(var.azure.account_tier, "Standard")
  account_replication_type = try(var.azure.replication_type, "LRS")
  account_kind             = try(var.azure.account_kind, "StorageV2")

  # Security
  enable_https_traffic_only       = try(var.azure.https_only, true)
  min_tls_version                 = try(var.azure.min_tls_version, "TLS1_2")
  allow_nested_items_to_be_public = try(var.azure.allow_public_access, false)

  # Blob properties
  blob_properties {
    versioning_enabled = try(var.azure.versioning_enabled, true)

    dynamic "delete_retention_policy" {
      for_each = try(var.azure.delete_retention_days, null) != null ? [1] : []
      content {
        days = var.azure.delete_retention_days
      }
    }

    dynamic "container_delete_retention_policy" {
      for_each = try(var.azure.container_delete_retention_days, null) != null ? [1] : []
      content {
        days = var.azure.container_delete_retention_days
      }
    }
  }

  # Network rules
  dynamic "network_rules" {
    for_each = try(var.azure.network_rules_enabled, false) ? [1] : []
    content {
      default_action             = try(var.azure.default_network_action, "Deny")
      bypass                     = try(var.azure.network_bypass, ["AzureServices"])
      ip_rules                   = try(var.azure.allowed_ip_ranges, [])
      virtual_network_subnet_ids = try(var.azure.allowed_subnet_ids, [])
    }
  }

  tags = {
    Name        = local.azure_storage_account_name
    ManagedBy   = "terraform"
    Application = "btp-object-storage"
  }
}

# Storage Container
resource "azurerm_storage_container" "container" {
  count                 = var.mode == "azure" ? 1 : 0
  name                  = try(var.azure.container_name, "btp-artifacts")
  storage_account_name  = azurerm_storage_account.storage[0].name
  container_access_type = "private"
}

# Management Policy for lifecycle management
resource "azurerm_storage_management_policy" "lifecycle" {
  count              = var.mode == "azure" && try(var.azure.lifecycle_rules_enabled, false) ? 1 : 0
  storage_account_id = azurerm_storage_account.storage[0].id

  rule {
    name    = "delete-old-versions"
    enabled = true

    filters {
      prefix_match = ["artifacts/"]
      blob_types   = ["blockBlob"]
    }

    actions {
      version {
        delete_after_days_since_creation = try(var.azure.old_version_retention_days, 90)
      }
    }
  }
}

# Generate SAS token for access (for S3-compatible access we'll use account keys)
# Note: Azure Blob Storage supports S3-compatible API via Data Lake Storage Gen2
# For S3 compatibility, we'll use the storage account keys

# Outputs
locals {
  # Blob endpoint
  azure_endpoint = var.mode == "azure" && length(azurerm_storage_account.storage) > 0 ? azurerm_storage_account.storage[0].primary_blob_endpoint : null

  # Container/bucket name
  azure_bucket = var.mode == "azure" ? try(var.azure.container_name, "btp-artifacts") : null

  # Access credentials (using storage account key for S3-compatible access)
  azure_access_key = var.mode == "azure" && length(azurerm_storage_account.storage) > 0 ? azurerm_storage_account.storage[0].name : null
  azure_secret_key = var.mode == "azure" && length(azurerm_storage_account.storage) > 0 ? azurerm_storage_account.storage[0].primary_access_key : null

  # Region
  azure_region = var.mode == "azure" ? local.azure_storage_location : null

  # Use path-style URLs (Azure uses virtual-hosted style by default, but can work with path style)
  azure_use_path_style = var.mode == "azure" ? false : null

  # Additional Azure-specific outputs
  azure_connection_string = var.mode == "azure" && length(azurerm_storage_account.storage) > 0 ? azurerm_storage_account.storage[0].primary_connection_string : null
  azure_storage_account_name = var.mode == "azure" ? local.azure_storage_account_name : null
}
