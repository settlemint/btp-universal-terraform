locals {
  supported_modes    = ["aws", "byo"]
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
  aws_config          = local.mode == "aws" ? var.aws : null
  aws_zone_id_input   = local.mode == "aws" ? try(local.aws_config.zone_id, null) : null
  aws_zone_name_input = local.mode == "aws" ? try(local.aws_config.zone_name, null) : null
  aws_main_alias      = local.mode == "aws" ? try(local.aws_config.alias, null) : null
  aws_wildcard_alias  = local.mode == "aws" ? try(local.aws_config.wildcard_alias, null) : null
}

data "aws_route53_zone" "selected" {
  count = local.mode == "aws" && local.aws_zone_id_input == null ? 1 : 0
  name  = local.aws_zone_name_input
}

locals {
  aws_zone_id        = local.mode == "aws" ? coalesce(local.aws_zone_id_input, try(data.aws_route53_zone.selected[0].zone_id, null)) : null
  aws_main_type      = local.mode == "aws" ? coalesce(try(local.aws_config.main_record_type, null), "A") : null
  aws_wildcard_type  = local.mode == "aws" ? coalesce(try(local.aws_config.wildcard_record_type, null), "CNAME") : null
  aws_main_value     = local.mode == "aws" ? try(local.aws_config.main_record_value, null) : null
  aws_wildcard_value = local.mode == "aws" ? coalesce(try(local.aws_config.wildcard_record_value, null), var.domain) : null
}

resource "aws_route53_record" "aws_main" {
  count   = local.mode == "aws" && local.aws_main_alias == null ? 1 : 0
  zone_id = local.aws_zone_id
  name    = var.domain
  type    = local.aws_main_type
  ttl     = coalesce(try(local.aws_config.main_ttl, null), 300)
  records = [local.aws_main_value]
}

resource "aws_route53_record" "aws_main_alias" {
  count   = local.mode == "aws" && local.aws_main_alias != null ? 1 : 0
  zone_id = local.aws_zone_id
  name    = var.domain
  type    = coalesce(try(local.aws_main_alias.type, null), local.aws_main_type)

  alias {
    name                   = local.aws_main_alias.name
    zone_id                = local.aws_main_alias.zone_id
    evaluate_target_health = coalesce(try(local.aws_main_alias.evaluate_target_health, null), false)
  }
}

resource "aws_route53_record" "aws_wildcard" {
  count   = local.mode == "aws" && var.enable_wildcard && local.aws_wildcard_alias == null ? 1 : 0
  zone_id = local.aws_zone_id
  name    = local.wildcard_hostname
  type    = local.aws_wildcard_type
  ttl     = coalesce(try(local.aws_config.wildcard_ttl, null), try(local.aws_config.main_ttl, null), 300)
  records = [local.aws_wildcard_value]
}

resource "aws_route53_record" "aws_wildcard_alias" {
  count   = local.mode == "aws" && var.enable_wildcard && local.aws_wildcard_alias != null ? 1 : 0
  zone_id = local.aws_zone_id
  name    = local.wildcard_hostname
  type    = coalesce(try(local.aws_wildcard_alias.type, null), local.aws_wildcard_type)

  alias {
    name                   = local.aws_wildcard_alias.name
    zone_id                = local.aws_wildcard_alias.zone_id
    evaluate_target_health = coalesce(try(local.aws_wildcard_alias.evaluate_target_health, null), false)
  }
}

locals {
  aws_records = local.mode == "aws" ? concat(
    [for r in aws_route53_record.aws_main : {
      name   = r.fqdn
      type   = local.aws_main_type
      target = local.aws_main_value
      ttl    = coalesce(try(local.aws_config.main_ttl, null), 300)
    }],
    [for r in aws_route53_record.aws_main_alias : {
      name   = r.fqdn
      type   = coalesce(try(local.aws_main_alias.type, null), local.aws_main_type)
      target = local.aws_main_alias.name
      alias  = true
    }],
    [for r in aws_route53_record.aws_wildcard : {
      name   = r.fqdn
      type   = local.aws_wildcard_type
      target = local.aws_wildcard_value
      ttl    = coalesce(try(local.aws_config.wildcard_ttl, null), try(local.aws_config.main_ttl, null), 300)
    }],
    [for r in aws_route53_record.aws_wildcard_alias : {
      name   = r.fqdn
      type   = coalesce(try(local.aws_wildcard_alias.type, null), local.aws_wildcard_type)
      target = local.aws_wildcard_alias.name
      alias  = true
    }]
  ) : []
}

locals {
  provider_records     = local.mode == "aws" ? local.aws_records : local.byo_records
  provider_annotations = local.mode == "aws" ? {} : local.byo_annotations
  provider_tls_hosts   = local.mode == "aws" ? [] : local.byo_tls_hosts
  provider_tls_secret  = local.mode == "aws" ? null : local.byo_tls_secret
  tls_hosts            = length(local.provider_tls_hosts) > 0 ? local.provider_tls_hosts : local.base_tls_hosts
  tls_secret_name      = coalesce(var.tls_secret_name, local.provider_tls_secret, local.tls_secret_default)
  ssl_redirect         = local.mode == "byo" ? coalesce(var.byo != null ? try(var.byo.ssl_redirect, null) : null, var.ssl_redirect) : var.ssl_redirect
  ingress_annotations  = merge(local.base_annotations, var.annotations, local.provider_annotations)
  records              = local.provider_records
  aws_zone_valid       = local.mode != "aws" || local.aws_zone_id != null
  unsupported_mode     = !contains(local.supported_modes, local.mode)
}
