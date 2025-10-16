locals {
  supported_modes    = ["aws", "azure", "gcp", "cf", "byo"]
  mode               = var.mode
  sanitized_domain   = replace(var.domain, ".", "-")
  wildcard_hostname  = var.enable_wildcard ? format("*.%s", var.domain) : null
  base_tls_hosts     = compact([var.domain, var.include_wildcard_in_tls && local.wildcard_hostname != null ? local.wildcard_hostname : null])
  base_annotations   = var.cert_manager_issuer != null ? { "cert-manager.io/cluster-issuer" = var.cert_manager_issuer } : {}
  byo_annotations    = local.mode == "byo" && var.byo != null ? try(var.byo.ingress_annotations, {}) : {}
  byo_tls_hosts      = local.mode == "byo" && var.byo != null ? try(var.byo.tls_hosts, []) : []
  byo_tls_secret     = local.mode == "byo" && var.byo != null ? try(var.byo.tls_secret_name, null) : null
  byo_records        = []
  tls_secret_default = var.release_name != null ? format("%s-tls", var.release_name) : format("%s-tls", local.sanitized_domain)
}

locals {
  provider_record_map = merge({
    byo   = local.byo_records
    aws   = []
    azure = []
    gcp   = []
    cf    = []
    }, {
    aws   = try(local.aws_records, [])
    azure = try(local.azure_records, [])
    gcp   = try(local.gcp_records, [])
    cf    = try(local.cf_records, [])
  })

  provider_annotation_map = merge({
    byo   = local.byo_annotations
    aws   = {}
    azure = {}
    gcp   = {}
    cf    = {}
    }, {
    aws   = try(local.aws_annotations, {})
    azure = try(local.azure_annotations, {})
    gcp   = try(local.gcp_annotations, {})
    cf    = try(local.cf_annotations, {})
  })

  provider_tls_host_map = merge({
    byo   = local.byo_tls_hosts
    aws   = []
    azure = []
    gcp   = []
    cf    = []
    }, {
    aws   = try(local.aws_tls_hosts, [])
    azure = try(local.azure_tls_hosts, [])
    gcp   = try(local.gcp_tls_hosts, [])
    cf    = try(local.cf_tls_hosts, [])
  })

  provider_tls_secret_map = merge({
    byo   = local.byo_tls_secret
    aws   = null
    azure = null
    gcp   = null
    cf    = null
    }, {
    aws   = try(local.aws_tls_secret, null)
    azure = try(local.azure_tls_secret, null)
    gcp   = try(local.gcp_tls_secret, null)
    cf    = try(local.cf_tls_secret, null)
  })
}

locals {
  provider_records     = try(local.provider_record_map[local.mode], [])
  provider_annotations = try(local.provider_annotation_map[local.mode], {})
  provider_tls_hosts   = try(local.provider_tls_host_map[local.mode], [])
  provider_tls_secret  = try(local.provider_tls_secret_map[local.mode], null)
  tls_hosts            = length(local.provider_tls_hosts) > 0 ? local.provider_tls_hosts : local.base_tls_hosts
  tls_secret_name      = coalesce(var.tls_secret_name, local.provider_tls_secret, local.tls_secret_default)
  ssl_redirect         = local.mode == "byo" ? coalesce(var.byo != null ? try(var.byo.ssl_redirect, null) : null, var.ssl_redirect) : var.ssl_redirect
  ingress_annotations  = merge(local.base_annotations, var.annotations, local.provider_annotations)
  records              = local.provider_records
  aws_zone_valid       = local.mode != "aws" || try(local.aws_zone_id, null) != null
  unsupported_mode     = !contains(local.supported_modes, local.mode)
}
