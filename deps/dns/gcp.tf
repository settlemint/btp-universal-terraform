# GCP Cloud DNS implementation

locals {
  gcp_config = var.mode == "gcp" && var.gcp != null ? var.gcp : null

  gcp_managed_zone = var.mode == "gcp" ? try(local.gcp_config.managed_zone, null) : null
  gcp_project      = var.mode == "gcp" ? try(local.gcp_config.project, null) : null

  gcp_main_type  = var.mode == "gcp" ? coalesce(try(local.gcp_config.main_record_type, null), "A") : null
  gcp_main_value = var.mode == "gcp" ? try(local.gcp_config.main_record_value, null) : null
  gcp_main_ttl   = var.mode == "gcp" ? coalesce(try(local.gcp_config.main_ttl, null), 300) : null

  gcp_wildcard_type  = var.mode == "gcp" ? coalesce(try(local.gcp_config.wildcard_record_type, null), "CNAME") : null
  gcp_wildcard_value = var.mode == "gcp" ? coalesce(try(local.gcp_config.wildcard_record_value, null), var.domain) : null
  gcp_wildcard_ttl   = var.mode == "gcp" ? coalesce(try(local.gcp_config.wildcard_ttl, null), local.gcp_main_ttl, 300) : null
}

# Get the managed zone
data "google_dns_managed_zone" "zone" {
  count   = var.mode == "gcp" ? 1 : 0
  project = local.gcp_project
  name    = local.gcp_managed_zone
}

# Main domain A record
resource "google_dns_record_set" "main" {
  count        = var.mode == "gcp" ? 1 : 0
  project      = local.gcp_project
  managed_zone = data.google_dns_managed_zone.zone[0].name
  name         = "${var.domain}."
  type         = local.gcp_main_type
  ttl          = local.gcp_main_ttl
  rrdatas      = [local.gcp_main_value]
}

# Wildcard CNAME record
resource "google_dns_record_set" "wildcard" {
  count        = var.mode == "gcp" && var.enable_wildcard ? 1 : 0
  project      = local.gcp_project
  managed_zone = data.google_dns_managed_zone.zone[0].name
  name         = "${local.wildcard_hostname}."
  type         = local.gcp_wildcard_type
  ttl          = local.gcp_wildcard_ttl
  rrdatas      = ["${local.gcp_wildcard_value}."]
}

locals {
  gcp_records = var.mode == "gcp" ? [
    {
      name  = var.domain
      type  = local.gcp_main_type
      value = local.gcp_main_value
    }
  ] : []

  gcp_annotations = var.mode == "gcp" ? {} : {}
  gcp_tls_hosts   = var.mode == "gcp" ? [var.domain] : []
  gcp_tls_secret  = var.mode == "gcp" ? try(var.tls_secret_name, "${var.release_name}-tls") : null
}
