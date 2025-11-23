# Azure AKS Cluster Implementation

locals {
  # Extract networking context from Azure VNet module or use provided values
  azure_vnet_id = try(var.azure.vnet_subnet_id, null) != null ? null : try(var.azure_context.vnet_id, null)
  azure_subnet_id = try(var.azure.vnet_subnet_id, null) != null ? var.azure.vnet_subnet_id : try(var.azure_context.subnet_id, null)
  azure_resource_group = try(var.azure.resource_group_name, var.azure_context.resource_group_name, "btp-resources")
  azure_location = try(var.azure.location, var.azure_context.location, "eastus")
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  count               = var.mode == "azure" ? 1 : 0
  name                = var.azure.cluster_name
  location            = local.azure_location
  resource_group_name = local.azure_resource_group
  dns_prefix          = var.azure.dns_prefix
  kubernetes_version  = var.azure.kubernetes_version

  # Default Node Pool
  default_node_pool {
    name                = try(var.azure.default_node_pool.name, "default")
    node_count          = try(var.azure.default_node_pool.enable_auto_scaling, true) ? null : try(var.azure.default_node_pool.node_count, 2)
    min_count           = try(var.azure.default_node_pool.enable_auto_scaling, true) ? try(var.azure.default_node_pool.min_count, 1) : null
    max_count           = try(var.azure.default_node_pool.enable_auto_scaling, true) ? try(var.azure.default_node_pool.max_count, 4) : null
    enable_auto_scaling = try(var.azure.default_node_pool.enable_auto_scaling, true)
    vm_size             = try(var.azure.default_node_pool.vm_size, "Standard_D2s_v3")
    os_disk_size_gb     = try(var.azure.default_node_pool.os_disk_size_gb, 50)
    vnet_subnet_id      = local.azure_subnet_id
    zones               = try(var.azure.default_node_pool.availability_zones, ["1", "2", "3"])
    node_labels         = try(var.azure.default_node_pool.node_labels, {})
    node_taints         = try(var.azure.default_node_pool.node_taints, [])

    upgrade_settings {
      max_surge = "10%"
    }
  }

  # Network Profile
  network_profile {
    network_plugin     = var.azure.network_plugin
    network_policy     = try(var.azure.network_policy, "azure")
    service_cidr       = try(var.azure.service_cidr, "10.1.0.0/16")
    dns_service_ip     = try(var.azure.dns_service_ip, "10.1.0.10")
    load_balancer_sku  = try(var.azure.load_balancer_sku, "standard")
  }

  # Identity (System-assigned Managed Identity)
  identity {
    type = var.azure.identity_type
  }

  # RBAC Configuration
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = try(var.azure.enable_azure_active_directory, false) ? [1] : []
    content {
      managed                = true
      azure_rbac_enabled     = try(var.azure.enable_azure_rbac, true)
    }
  }

  # Monitoring
  dynamic "oms_agent" {
    for_each = try(var.azure.enable_log_analytics, false) && var.azure.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.azure.log_analytics_workspace_id
    }
  }

  # Automatic upgrades
  automatic_channel_upgrade = "patch"

  tags = merge(
    {
      Name        = var.azure.cluster_name
      ManagedBy   = "terraform"
      Application = "btp-k8s-cluster"
    },
    try(var.azure.tags, {})
  )

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }
}

# Additional Node Pools
resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  for_each = var.mode == "azure" ? try(var.azure.additional_node_pools, {}) : {}

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main[0].id
  vm_size               = try(each.value.vm_size, "Standard_D2s_v3")
  node_count            = try(each.value.enable_auto_scaling, true) ? null : try(each.value.node_count, 2)
  min_count             = try(each.value.enable_auto_scaling, true) ? try(each.value.min_count, 1) : null
  max_count             = try(each.value.enable_auto_scaling, true) ? try(each.value.max_count, 4) : null
  enable_auto_scaling   = try(each.value.enable_auto_scaling, true)
  os_disk_size_gb       = try(each.value.os_disk_size_gb, 50)
  vnet_subnet_id        = local.azure_subnet_id
  zones                 = try(each.value.availability_zones, ["1", "2", "3"])
  node_labels           = try(each.value.node_labels, {})
  node_taints           = try(each.value.node_taints, [])

  upgrade_settings {
    max_surge = "10%"
  }

  tags = merge(
    {
      Name        = "${var.azure.cluster_name}-${each.key}"
      ManagedBy   = "terraform"
      Application = "btp-k8s-cluster"
    },
    try(var.azure.tags, {})
  )

  lifecycle {
    ignore_changes = [
      node_count
    ]
  }
}

# Kubeconfig for AKS
locals {
  azure_kubeconfig = var.mode == "azure" && length(azurerm_kubernetes_cluster.main) > 0 ? azurerm_kubernetes_cluster.main[0].kube_config_raw : null

  azure_cluster_name     = var.mode == "azure" && length(azurerm_kubernetes_cluster.main) > 0 ? azurerm_kubernetes_cluster.main[0].name : null
  azure_cluster_endpoint = var.mode == "azure" && length(azurerm_kubernetes_cluster.main) > 0 ? azurerm_kubernetes_cluster.main[0].kube_config[0].host : null
  azure_cluster_ca_cert  = var.mode == "azure" && length(azurerm_kubernetes_cluster.main) > 0 ? base64decode(azurerm_kubernetes_cluster.main[0].kube_config[0].cluster_ca_certificate) : null
  azure_cluster_version  = var.mode == "azure" && length(azurerm_kubernetes_cluster.main) > 0 ? azurerm_kubernetes_cluster.main[0].kubernetes_version : null

  # Client credentials for authentication
  azure_client_certificate = var.mode == "azure" && length(azurerm_kubernetes_cluster.main) > 0 ? base64decode(azurerm_kubernetes_cluster.main[0].kube_config[0].client_certificate) : null
  azure_client_key = var.mode == "azure" && length(azurerm_kubernetes_cluster.main) > 0 ? base64decode(azurerm_kubernetes_cluster.main[0].kube_config[0].client_key) : null
}
