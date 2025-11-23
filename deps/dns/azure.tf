# Azure DNS implementation

locals {
  # Extract context
  azure_dns_rg = try(var.azure.resource_group_name, var.azure_network.resource_group_name, "btp-resources")

  # Extract zone name from domain (e.g., "example.com" from "btp.example.com")
  azure_zone_name = try(var.azure.zone_name, var.domain)
}

# Data source for existing DNS Zone (if managed externally)
data "azurerm_dns_zone" "existing" {
  count               = var.mode == "azure" && try(var.azure.use_existing_zone, false) ? 1 : 0
  name                = local.azure_zone_name
  resource_group_name = local.azure_dns_rg
}

# DNS Zone (create if not using existing)
resource "azurerm_dns_zone" "zone" {
  count               = var.mode == "azure" && !try(var.azure.use_existing_zone, false) ? 1 : 0
  name                = local.azure_zone_name
  resource_group_name = local.azure_dns_rg

  tags = {
    Name        = local.azure_zone_name
    ManagedBy   = "terraform"
    Application = "btp-dns"
  }
}

# Get ingress IP from Kubernetes service
data "kubernetes_service" "ingress" {
  count = var.mode == "azure" && try(var.create_dns_records, true) ? 1 : 0

  metadata {
    name      = try(var.ingress_service_name, "ingress-nginx-controller")
    namespace = try(var.ingress_namespace, "btp-deps")
  }
}

locals {
  # Determine zone ID
  azure_zone_id = var.mode == "azure" ? (
    try(var.azure.use_existing_zone, false) ?
    data.azurerm_dns_zone.existing[0].id :
    azurerm_dns_zone.zone[0].id
  ) : null

  # Get ingress IP
  azure_ingress_ip = var.mode == "azure" && length(data.kubernetes_service.ingress) > 0 ? (
    try(data.kubernetes_service.ingress[0].status[0].load_balancer[0].ingress[0].ip, null)
  ) : try(var.azure.main_record_value, null)
}

# Main A record (e.g., btp.example.com)
resource "azurerm_dns_a_record" "main" {
  count               = var.mode == "azure" && try(var.create_dns_records, true) && local.azure_ingress_ip != null ? 1 : 0
  name                = try(var.azure.subdomain, "@")
  zone_name           = local.azure_zone_name
  resource_group_name = local.azure_dns_rg
  ttl                 = try(var.azure.main_ttl, 300)
  records             = [local.azure_ingress_ip]

  tags = {
    Name        = "${var.domain}-main"
    ManagedBy   = "terraform"
    Application = "btp-dns"
  }

  depends_on = [
    azurerm_dns_zone.zone,
    data.azurerm_dns_zone.existing
  ]
}

# Wildcard CNAME record (e.g., *.btp.example.com -> btp.example.com)
resource "azurerm_dns_cname_record" "wildcard" {
  count               = var.mode == "azure" && try(var.enable_wildcard, true) && try(var.create_dns_records, true) ? 1 : 0
  name                = "*"
  zone_name           = local.azure_zone_name
  resource_group_name = local.azure_dns_rg
  ttl                 = try(var.azure.wildcard_ttl, 300)
  record              = try(var.azure.wildcard_record_value, var.domain)

  tags = {
    Name        = "${var.domain}-wildcard"
    ManagedBy   = "terraform"
    Application = "btp-dns"
  }

  depends_on = [
    azurerm_dns_zone.zone,
    data.azurerm_dns_zone.existing,
    azurerm_dns_a_record.main
  ]
}

# Outputs for ingress configuration
locals {
  # DNS records created
  azure_records = var.mode == "azure" && try(var.create_dns_records, true) ? [
    {
      name  = try(var.azure.subdomain, var.domain)
      type  = "A"
      value = local.azure_ingress_ip
    }
  ] : []

  # Ingress annotations for Azure
  azure_annotations = var.mode == "azure" ? {
    "kubernetes.io/ingress.class"                   = "nginx"
    "cert-manager.io/cluster-issuer"                = try(var.cert_manager_issuer, "letsencrypt-prod")
    "nginx.ingress.kubernetes.io/ssl-redirect"      = try(var.ssl_redirect, "true")
    "nginx.ingress.kubernetes.io/force-ssl-redirect" = try(var.ssl_redirect, "true")
  } : {}

  # TLS hosts
  azure_tls_hosts = var.mode == "azure" && try(var.enable_wildcard, true) && try(var.include_wildcard_in_tls, true) ? [
    var.domain,
    "*.${var.domain}"
  ] : (var.mode == "azure" ? [var.domain] : [])

  # TLS secret name
  azure_tls_secret = var.mode == "azure" ? "${replace(var.domain, ".", "-")}-tls" : null

  # Zone nameservers (for domain delegation)
  azure_nameservers = var.mode == "azure" ? (
    try(var.azure.use_existing_zone, false) ?
    data.azurerm_dns_zone.existing[0].name_servers :
    azurerm_dns_zone.zone[0].name_servers
  ) : []
}
