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
  count = var.mode == "aws" && local.aws_zone_id_input == null ? 1 : 0
  name  = local.aws_zone_name_input
}

locals {
  aws_zone_id        = var.mode == "aws" ? coalesce(local.aws_zone_id_input, try(data.aws_route53_zone.selected[0].zone_id, null)) : null
  aws_main_type      = var.mode == "aws" ? coalesce(try(local.aws_config.main_record_type, null), "A") : null
  aws_wildcard_type  = var.mode == "aws" ? coalesce(try(local.aws_config.wildcard_record_type, null), "CNAME") : null
  aws_main_value     = var.mode == "aws" ? try(local.aws_config.main_record_value, null) : null
  aws_wildcard_value = var.mode == "aws" ? coalesce(try(local.aws_config.wildcard_record_value, null), var.domain) : null
}

resource "aws_route53_record" "main" {
  count   = var.mode == "aws" && local.aws_main_alias == null ? 1 : 0
  zone_id = local.aws_zone_id
  name    = var.domain
  type    = local.aws_main_type
  ttl     = coalesce(try(local.aws_config.main_ttl, null), 300)
  records = [local.aws_main_value]
}

resource "aws_route53_record" "main_alias" {
  count   = var.mode == "aws" && local.aws_main_alias != null ? 1 : 0
  zone_id = local.aws_zone_id
  name    = var.domain
  type    = coalesce(try(local.aws_main_alias.type, null), local.aws_main_type)

  alias {
    name                   = local.aws_main_alias.name
    zone_id                = local.aws_main_alias.zone_id
    evaluate_target_health = coalesce(try(local.aws_main_alias.evaluate_target_health, null), false)
  }
}

resource "aws_route53_record" "wildcard" {
  count   = var.mode == "aws" && var.enable_wildcard && local.aws_wildcard_alias == null ? 1 : 0
  zone_id = local.aws_zone_id
  name    = local.wildcard_hostname
  type    = local.aws_wildcard_type
  ttl     = coalesce(try(local.aws_config.wildcard_ttl, null), try(local.aws_config.main_ttl, null), 300)
  records = [local.aws_wildcard_value]
}

resource "aws_route53_record" "wildcard_alias" {
  count   = var.mode == "aws" && var.enable_wildcard && local.aws_wildcard_alias != null ? 1 : 0
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
  aws_records = var.mode == "aws" ? concat(
    [for r in aws_route53_record.main : {
      name   = r.fqdn
      type   = local.aws_main_type
      target = local.aws_main_value
      ttl    = coalesce(try(local.aws_config.main_ttl, null), 300)
    }],
    [for r in aws_route53_record.main_alias : {
      name   = r.fqdn
      type   = coalesce(try(local.aws_main_alias.type, null), local.aws_main_type)
      target = local.aws_main_alias.name
      alias  = true
    }],
    [for r in aws_route53_record.wildcard : {
      name   = r.fqdn
      type   = local.aws_wildcard_type
      target = local.aws_wildcard_value
      ttl    = coalesce(try(local.aws_config.wildcard_ttl, null), try(local.aws_config.main_ttl, null), 300)
    }],
    [for r in aws_route53_record.wildcard_alias : {
      name   = r.fqdn
      type   = coalesce(try(local.aws_wildcard_alias.type, null), local.aws_wildcard_type)
      target = local.aws_wildcard_alias.name
      alias  = true
    }]
  ) : []

  aws_annotations = {}
  aws_tls_hosts   = []
  aws_tls_secret  = null
}
