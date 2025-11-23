# Azure mode: Azure Key Vault integration

# Get current client/tenant information
data "azurerm_client_config" "current" {
  count = var.mode == "azure" ? 1 : 0
}

locals {
  # Extract context
  azure_kv_rg       = try(var.azure.resource_group_name, var.azure_network.resource_group_name, "btp-resources")
  azure_kv_location = try(var.azure.location, var.azure_network.location, "eastus")
  azure_tenant_id   = var.mode == "azure" ? data.azurerm_client_config.current[0].tenant_id : null
  azure_object_id   = var.mode == "azure" ? data.azurerm_client_config.current[0].object_id : null
}

# Azure Key Vault
resource "azurerm_key_vault" "vault" {
  count                       = var.mode == "azure" ? 1 : 0
  name                        = var.azure.key_vault_name
  location                    = local.azure_kv_location
  resource_group_name         = local.azure_kv_rg
  tenant_id                   = local.azure_tenant_id
  sku_name                    = try(var.azure.sku_name, "standard")
  enabled_for_disk_encryption = try(var.azure.enabled_for_disk_encryption, false)
  enabled_for_deployment      = try(var.azure.enabled_for_deployment, true)
  enabled_for_template_deployment = try(var.azure.enabled_for_template_deployment, true)
  soft_delete_retention_days  = try(var.azure.soft_delete_retention_days, 7)
  purge_protection_enabled    = try(var.azure.purge_protection_enabled, false)

  # Network ACLs
  dynamic "network_acls" {
    for_each = try(var.azure.network_acls_enabled, false) ? [1] : []
    content {
      default_action             = try(var.azure.default_network_action, "Deny")
      bypass                     = try(var.azure.network_bypass, "AzureServices")
      ip_rules                   = try(var.azure.allowed_ip_ranges, [])
      virtual_network_subnet_ids = try(var.azure.allowed_subnet_ids, [])
    }
  }

  tags = {
    Name        = var.azure.key_vault_name
    ManagedBy   = "terraform"
    Application = "btp-secrets"
  }
}

# Access Policy for Terraform Service Principal / User
resource "azurerm_key_vault_access_policy" "terraform" {
  count        = var.mode == "azure" ? 1 : 0
  key_vault_id = azurerm_key_vault.vault[0].id
  tenant_id    = local.azure_tenant_id
  object_id    = local.azure_object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Purge",
    "Recover"
  ]

  key_permissions = [
    "Get",
    "List",
    "Create",
    "Delete",
    "Purge",
    "Recover"
  ]

  certificate_permissions = [
    "Get",
    "List",
    "Create",
    "Delete",
    "Purge"
  ]
}

# Access Policy for AKS (via managed identity - will be added by k8s module)
# This is a placeholder - actual integration with AKS requires the cluster's managed identity

# Store platform secrets in Key Vault
resource "azurerm_key_vault_secret" "grafana_admin_password" {
  count        = var.mode == "azure" && try(var.secrets.grafana_admin_password, null) != null ? 1 : 0
  name         = "grafana-admin-password"
  value        = var.secrets.grafana_admin_password
  key_vault_id = azurerm_key_vault.vault[0].id

  depends_on = [azurerm_key_vault_access_policy.terraform]
}

resource "azurerm_key_vault_secret" "jwt_signing_key" {
  count        = var.mode == "azure" && try(var.secrets.jwt_signing_key, null) != null ? 1 : 0
  name         = "jwt-signing-key"
  value        = var.secrets.jwt_signing_key
  key_vault_id = azurerm_key_vault.vault[0].id

  depends_on = [azurerm_key_vault_access_policy.terraform]
}

resource "azurerm_key_vault_secret" "state_encryption_key" {
  count        = var.mode == "azure" && try(var.secrets.state_encryption_key, null) != null ? 1 : 0
  name         = "state-encryption-key"
  value        = var.secrets.state_encryption_key
  key_vault_id = azurerm_key_vault.vault[0].id

  depends_on = [azurerm_key_vault_access_policy.terraform]
}

resource "azurerm_key_vault_secret" "ipfs_cluster_secret" {
  count        = var.mode == "azure" && try(var.secrets.ipfs_cluster_secret, null) != null ? 1 : 0
  name         = "ipfs-cluster-secret"
  value        = var.secrets.ipfs_cluster_secret
  key_vault_id = azurerm_key_vault.vault[0].id

  depends_on = [azurerm_key_vault_access_policy.terraform]
}

# Outputs
locals {
  azure_vault_addr = var.mode == "azure" && length(azurerm_key_vault.vault) > 0 ? azurerm_key_vault.vault[0].vault_uri : null
  azure_vault_name = var.mode == "azure" ? var.azure.key_vault_name : null
  azure_tenant_id_output = var.mode == "azure" ? local.azure_tenant_id : null

  # For AKS workload identity integration
  azure_kv_mount = var.mode == "azure" ? "azure-kv" : null

  # Secret paths (for CSI driver reference)
  azure_paths = var.mode == "azure" ? [
    "grafana-admin-password",
    "jwt-signing-key",
    "state-encryption-key",
    "ipfs-cluster-secret"
  ] : []
}
