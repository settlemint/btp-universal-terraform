# AWS Route53 implementation

locals {
  aws_config_default = {
    zone_id               = null
    zone_name             = null
    main_record_type      = null
    main_record_value     = null
    main_ttl              = null
    alias                 = null
    wildcard_record_type  = null
    wildcard_record_value = null
    wildcard_ttl          = null
    wildcard_alias        = null
  }

  aws_config = var.mode == "aws" && var.aws != null ? merge(local.aws_config_default, var.aws) : local.aws_config_default

  aws_zone_id_input   = var.mode == "aws" ? try(local.aws_config.zone_id, null) : null
  aws_zone_name_input = var.mode == "aws" ? try(local.aws_config.zone_name, null) : null

  aws_main_alias     = var.mode == "aws" ? try(local.aws_config.alias, null) : null
  aws_wildcard_alias = var.mode == "aws" ? try(local.aws_config.wildcard_alias, null) : null
}

data "aws_route53_zone" "selected" {
  count = var.mode == "aws" ? 1 : 0

  zone_id = local.aws_zone_id_input
  name    = local.aws_zone_id_input == null ? local.aws_zone_name_input : null
}

locals {
  aws_zone_lookup_id = length(data.aws_route53_zone.selected) > 0 ? try(data.aws_route53_zone.selected[0].zone_id, null) : null
  aws_zone_id        = var.mode == "aws" ? coalesce(local.aws_zone_id_input, local.aws_zone_lookup_id) : null
  aws_main_type      = var.mode == "aws" ? coalesce(try(local.aws_config.main_record_type, null), "A") : null
  aws_wildcard_type  = var.mode == "aws" ? coalesce(try(local.aws_config.wildcard_record_type, null), "CNAME") : null
  aws_main_value     = var.mode == "aws" ? try(local.aws_config.main_record_value, null) : null
  aws_wildcard_value = var.mode == "aws" ? coalesce(try(local.aws_config.wildcard_record_value, null), var.domain) : null
}

resource "aws_route53_record" "main" {
  count   = var.mode == "aws" ? 1 : 0
  zone_id = local.aws_zone_id
  name    = var.domain
  type    = local.aws_main_alias != null ? coalesce(try(local.aws_main_alias.type, null), local.aws_main_type) : local.aws_main_type
  ttl     = local.aws_main_alias == null ? coalesce(try(local.aws_config.main_ttl, null), 300) : null
  records = local.aws_main_alias == null && local.aws_main_value != null ? [local.aws_main_value] : null

  dynamic "alias" {
    for_each = local.aws_main_alias != null ? [local.aws_main_alias] : []
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = coalesce(try(alias.value.evaluate_target_health, null), false)
    }
  }

  lifecycle {
    precondition {
      condition     = local.aws_main_alias != null || local.aws_main_value != null
      error_message = "dns.aws.main_record_value must be set when alias is not provided."
    }
  }
}

resource "aws_route53_record" "wildcard" {
  count   = var.mode == "aws" && var.enable_wildcard ? 1 : 0
  zone_id = local.aws_zone_id
  name    = local.wildcard_hostname
  type    = local.aws_wildcard_alias != null ? coalesce(try(local.aws_wildcard_alias.type, null), local.aws_wildcard_type) : local.aws_wildcard_type
  ttl     = local.aws_wildcard_alias == null ? coalesce(try(local.aws_config.wildcard_ttl, null), try(local.aws_config.main_ttl, null), 300) : null
  records = local.aws_wildcard_alias == null && local.aws_wildcard_value != null ? [local.aws_wildcard_value] : null

  dynamic "alias" {
    for_each = local.aws_wildcard_alias != null ? [local.aws_wildcard_alias] : []
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = coalesce(try(alias.value.evaluate_target_health, null), false)
    }
  }
}

locals {
  aws_records = var.mode == "aws" ? concat(
    [for r in aws_route53_record.main : try(r.alias[0].name, null) != null ? {
      name   = r.fqdn
      type   = r.type
      target = r.alias[0].name
      alias  = true
      } : {
      name   = r.fqdn
      type   = r.type
      target = length(try(r.records, [])) > 0 ? tolist(r.records)[0] : null
      ttl    = r.ttl
    }],
    [for r in aws_route53_record.wildcard : try(r.alias[0].name, null) != null ? {
      name   = r.fqdn
      type   = r.type
      target = r.alias[0].name
      alias  = true
      } : {
      name   = r.fqdn
      type   = r.type
      target = length(try(r.records, [])) > 0 ? tolist(r.records)[0] : null
      ttl    = r.ttl
    }]
  ) : []

  aws_annotations = {}
  aws_tls_hosts   = []
  aws_tls_secret  = null
}
