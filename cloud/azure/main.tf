# Azure VNet and Networking Module
# Creates VNet, subnets, NSGs, and NAT Gateway for BTP infrastructure

locals {
  vnet_defaults = {
    create_vnet         = true
    resource_group_name = "btp-resources"
    location            = "eastus"
    vnet_name           = "btp-vnet"
    vnet_cidr           = "10.0.0.0/16"

    # Subnet configuration
    subnet_public_cidr  = "10.0.0.0/24"
    subnet_private_cidr = "10.0.1.0/24"
    subnet_aks_cidr     = "10.0.2.0/23"  # Larger for AKS nodes

    # NAT Gateway
    enable_nat_gateway = true

    # Network Security
    enable_ddos_protection = false

    # Existing resources (BYO mode)
    existing_vnet_id          = null
    existing_vnet_name        = null
    existing_resource_group   = null
    existing_subnet_aks_id    = null
    existing_subnet_private_id = null
  }

  vnet_input  = merge(local.vnet_defaults, try(var.config.azure, var.config, {}))
  create_vnet = local.vnet_input.create_vnet
}

# Resource Group
resource "azurerm_resource_group" "main" {
  count    = local.create_vnet ? 1 : 0
  name     = local.vnet_input.resource_group_name
  location = local.vnet_input.location

  tags = {
    ManagedBy   = "terraform"
    Application = "btp-vnet"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  count               = local.create_vnet ? 1 : 0
  name                = local.vnet_input.vnet_name
  location            = azurerm_resource_group.main[0].location
  resource_group_name = azurerm_resource_group.main[0].name
  address_space       = [local.vnet_input.vnet_cidr]

  tags = {
    Name        = local.vnet_input.vnet_name
    ManagedBy   = "terraform"
    Application = "btp-vnet"
  }
}

# Public Subnet (for NAT Gateway, Load Balancers)
resource "azurerm_subnet" "public" {
  count                = local.create_vnet ? 1 : 0
  name                 = "${local.vnet_input.vnet_name}-public"
  resource_group_name  = azurerm_resource_group.main[0].name
  virtual_network_name = azurerm_virtual_network.main[0].name
  address_prefixes     = [local.vnet_input.subnet_public_cidr]
}

# Private Subnet (for managed services: PostgreSQL, Redis, etc.)
resource "azurerm_subnet" "private" {
  count                = local.create_vnet ? 1 : 0
  name                 = "${local.vnet_input.vnet_name}-private"
  resource_group_name  = azurerm_resource_group.main[0].name
  virtual_network_name = azurerm_virtual_network.main[0].name
  address_prefixes     = [local.vnet_input.subnet_private_cidr]

  # Delegate to Azure Database for PostgreSQL
  delegation {
    name = "postgres-delegation"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }

  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.Sql"
  ]
}

# AKS Subnet
resource "azurerm_subnet" "aks" {
  count                = local.create_vnet ? 1 : 0
  name                 = "${local.vnet_input.vnet_name}-aks"
  resource_group_name  = azurerm_resource_group.main[0].name
  virtual_network_name = azurerm_virtual_network.main[0].name
  address_prefixes     = [local.vnet_input.subnet_aks_cidr]

  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.ContainerRegistry"
  ]
}

# Public IP for NAT Gateway
resource "azurerm_public_ip" "nat" {
  count               = local.create_vnet && local.vnet_input.enable_nat_gateway ? 1 : 0
  name                = "${local.vnet_input.vnet_name}-nat-ip"
  location            = azurerm_resource_group.main[0].location
  resource_group_name = azurerm_resource_group.main[0].name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]

  tags = {
    Name        = "${local.vnet_input.vnet_name}-nat-ip"
    ManagedBy   = "terraform"
    Application = "btp-vnet"
  }
}

# NAT Gateway
resource "azurerm_nat_gateway" "main" {
  count               = local.create_vnet && local.vnet_input.enable_nat_gateway ? 1 : 0
  name                = "${local.vnet_input.vnet_name}-nat"
  location            = azurerm_resource_group.main[0].location
  resource_group_name = azurerm_resource_group.main[0].name
  sku_name            = "Standard"

  tags = {
    Name        = "${local.vnet_input.vnet_name}-nat"
    ManagedBy   = "terraform"
    Application = "btp-vnet"
  }
}

# Associate Public IP with NAT Gateway
resource "azurerm_nat_gateway_public_ip_association" "main" {
  count                = local.create_vnet && local.vnet_input.enable_nat_gateway ? 1 : 0
  nat_gateway_id       = azurerm_nat_gateway.main[0].id
  public_ip_address_id = azurerm_public_ip.nat[0].id
}

# Associate NAT Gateway with AKS Subnet
resource "azurerm_subnet_nat_gateway_association" "aks" {
  count          = local.create_vnet && local.vnet_input.enable_nat_gateway ? 1 : 0
  subnet_id      = azurerm_subnet.aks[0].id
  nat_gateway_id = azurerm_nat_gateway.main[0].id
}

# Network Security Group for AKS
resource "azurerm_network_security_group" "aks" {
  count               = local.create_vnet ? 1 : 0
  name                = "${local.vnet_input.vnet_name}-aks-nsg"
  location            = azurerm_resource_group.main[0].location
  resource_group_name = azurerm_resource_group.main[0].name

  # Allow inbound HTTPS
  security_rule {
    name                       = "allow-https"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow inbound HTTP
  security_rule {
    name                       = "allow-http"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Name        = "${local.vnet_input.vnet_name}-aks-nsg"
    ManagedBy   = "terraform"
    Application = "btp-vnet"
  }
}

# Associate NSG with AKS Subnet
resource "azurerm_subnet_network_security_group_association" "aks" {
  count                     = local.create_vnet ? 1 : 0
  subnet_id                 = azurerm_subnet.aks[0].id
  network_security_group_id = azurerm_network_security_group.aks[0].id
}

# Network Security Group for Private Subnet
resource "azurerm_network_security_group" "private" {
  count               = local.create_vnet ? 1 : 0
  name                = "${local.vnet_input.vnet_name}-private-nsg"
  location            = azurerm_resource_group.main[0].location
  resource_group_name = azurerm_resource_group.main[0].name

  # Allow PostgreSQL from VNet
  security_rule {
    name                       = "allow-postgres"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Allow Redis from VNet
  security_rule {
    name                       = "allow-redis"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["6379", "6380"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  tags = {
    Name        = "${local.vnet_input.vnet_name}-private-nsg"
    ManagedBy   = "terraform"
    Application = "btp-vnet"
  }
}

# Associate NSG with Private Subnet
resource "azurerm_subnet_network_security_group_association" "private" {
  count                     = local.create_vnet ? 1 : 0
  subnet_id                 = azurerm_subnet.private[0].id
  network_security_group_id = azurerm_network_security_group.private[0].id
}

# Data sources for existing VNet (BYO mode)
data "azurerm_virtual_network" "existing" {
  count               = !local.create_vnet && local.vnet_input.existing_vnet_name != null ? 1 : 0
  name                = local.vnet_input.existing_vnet_name
  resource_group_name = local.vnet_input.existing_resource_group
}

data "azurerm_subnet" "existing_aks" {
  count                = !local.create_vnet && local.vnet_input.existing_subnet_aks_id != null ? 1 : 0
  name                 = local.vnet_input.existing_subnet_aks_id
  virtual_network_name = local.vnet_input.existing_vnet_name
  resource_group_name  = local.vnet_input.existing_resource_group
}

# Output locals
locals {
  vnet_id   = local.create_vnet ? azurerm_virtual_network.main[0].id : (local.vnet_input.existing_vnet_id != null ? local.vnet_input.existing_vnet_id : null)
  vnet_name = local.create_vnet ? azurerm_virtual_network.main[0].name : local.vnet_input.existing_vnet_name

  resource_group_name = local.create_vnet ? azurerm_resource_group.main[0].name : local.vnet_input.existing_resource_group
  location            = local.create_vnet ? azurerm_resource_group.main[0].location : local.vnet_input.location

  subnet_aks_id     = local.create_vnet ? azurerm_subnet.aks[0].id : local.vnet_input.existing_subnet_aks_id
  subnet_private_id = local.create_vnet ? azurerm_subnet.private[0].id : local.vnet_input.existing_subnet_private_id
  subnet_public_id  = local.create_vnet ? azurerm_subnet.public[0].id : null

  nat_gateway_ip = local.create_vnet && local.vnet_input.enable_nat_gateway ? azurerm_public_ip.nat[0].ip_address : null

  network = {
    vnet_id            = local.vnet_id
    vnet_name          = local.vnet_name
    vnet_cidr          = local.create_vnet ? local.vnet_input.vnet_cidr : null
    resource_group     = local.resource_group_name
    location           = local.location
    private_subnet_ids = [local.subnet_private_id]
    public_subnet_ids  = local.subnet_public_id != null ? [local.subnet_public_id] : []
    aks_subnet_id      = local.subnet_aks_id
    nat_gateway_ip     = local.nat_gateway_ip
  }

  security_groups = {
    aks     = local.create_vnet ? azurerm_network_security_group.aks[0].id : null
    private = local.create_vnet ? azurerm_network_security_group.private[0].id : null
  }

  k8s_context = {
    vnet_id                  = local.vnet_id
    vnet_name                = local.vnet_name
    resource_group_name      = local.resource_group_name
    location                 = local.location
    subnet_id                = local.subnet_aks_id
    subnet_ids               = [local.subnet_aks_id]
    control_plane_subnet_ids = []
    security_group_ids       = []
  }

  dependency_context = {
    postgres = {
      vnet_id             = local.vnet_id
      resource_group_name = local.resource_group_name
      location            = local.location
      subnet_id           = local.subnet_private_id
      private_dns_zone_id = null # Will be created by postgres module
    }
    redis = {
      vnet_id             = local.vnet_id
      resource_group_name = local.resource_group_name
      location            = local.location
      subnet_id           = local.subnet_private_id
    }
    storage = {
      resource_group_name = local.resource_group_name
      location            = local.location
    }
    keyvault = {
      resource_group_name = local.resource_group_name
      location            = local.location
    }
  }
}
