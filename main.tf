locals {
  # Default namespace for all dependencies
  default_namespace = "btp-deps"

  # Simplified namespace resolution with clear precedence:
  # 1. Component-specific k8s.namespace
  # 2. Global namespace map
  # 3. Default namespace
  namespaces = {
    ingress_tls    = coalesce(try(var.ingress_tls.k8s.namespace, null), var.namespaces.ingress_tls, local.default_namespace)
    postgres       = coalesce(try(var.postgres.k8s.namespace, null), var.namespaces.postgres, local.default_namespace)
    redis          = coalesce(try(var.redis.k8s.namespace, null), var.namespaces.redis, local.default_namespace)
    object_storage = coalesce(try(var.object_storage.k8s.namespace, null), var.namespaces.object_storage, local.default_namespace)
    metrics_logs   = coalesce(try(var.metrics_logs.k8s.namespace, null), var.namespaces.metrics_logs, local.default_namespace)
    oauth          = coalesce(try(var.oauth.k8s.namespace, null), var.namespaces.oauth, local.default_namespace)
    secrets        = coalesce(try(var.secrets.k8s.namespace, null), var.namespaces.secrets, local.default_namespace)
  }

  dependency_order = [
    "ingress_tls",
    "postgres",
    "redis",
    "object_storage",
    "metrics_logs",
    "oauth",
    "secrets"
  ]

  dependency_modes = {
    ingress_tls    = try(var.ingress_tls.mode, "k8s")
    postgres       = try(var.postgres.mode, "k8s")
    redis          = try(var.redis.mode, "k8s")
    object_storage = try(var.object_storage.mode, "k8s")
    metrics_logs   = try(var.metrics_logs.mode, "k8s")
    oauth          = try(var.oauth.mode, "disabled")
    secrets        = try(var.secrets.mode, "k8s")
  }

  k8s_dependency_namespaces = distinct([
    for component in local.dependency_order : local.namespaces[component]
    if local.dependency_modes[component] == "k8s"
  ])

  # OAuth configuration
  oauth_enabled = try(var.oauth.mode, "disabled") != "disabled"

  # Default null OAuth outputs
  oauth_null_outputs = {
    issuer        = null
    admin_url     = null
    client_id     = null
    client_secret = null
    scopes        = []
    callback_urls = []
  }

  # Select OAuth outputs based on whether module is enabled
  oauth_outputs = local.oauth_enabled && length(module.oauth) > 0 ? module.oauth[0] : local.oauth_null_outputs

  ingress_lb_lookup_enabled = coalesce(
    try(var.ingress_tls.k8s.load_balancer_lookup_enabled, null),
    module.k8s_cluster.mode == "aws"
  )
}

# AWS cloud scaffolding (VPC, shared networking)
module "cloud_aws" {
  count  = var.platform == "aws" ? 1 : 0
  source = "./cloud/aws"

  vpc = try(var.vpc.aws, {})
}

# Kubernetes Cluster Module - Creates managed K8s cluster (EKS, AKS, GKE) or uses existing cluster
# Deployed after VPC but before all other dependencies
module "k8s_cluster" {
  source = "./deps/k8s_cluster"

  mode = try(var.k8s_cluster.mode, "disabled")
  aws  = try(var.k8s_cluster.aws, {})
  aws_context = length(module.cloud_aws) > 0 ? module.cloud_aws[0].k8s_context : {
    vpc_id                   = null
    subnet_ids               = []
    control_plane_subnet_ids = []
    security_group_ids       = []
  }
  azure = try(var.k8s_cluster.azure, {})
  gcp   = try(var.k8s_cluster.gcp, {})
  byo   = try(var.k8s_cluster.byo, null)
}

resource "kubernetes_namespace" "deps" {
  for_each = { for ns in local.k8s_dependency_namespaces : ns => ns }

  metadata {
    name = each.value
  }

  depends_on = [module.k8s_cluster]
}

module "ingress_tls" {
  source = "./deps/ingress_tls"

  mode = try(var.ingress_tls.mode, "k8s")
  namespace = try(
    kubernetes_namespace.deps[local.namespaces.ingress_tls].metadata[0].name,
    local.namespaces.ingress_tls
  )
  manage_namespace           = false
  nginx_chart_version        = try(var.ingress_tls.k8s.nginx_chart_version, null)
  cert_manager_chart_version = try(var.ingress_tls.k8s.cert_manager_chart_version, null)
  release_name_nginx         = try(var.ingress_tls.k8s.release_name_nginx, null)
  release_name_cert_manager  = try(var.ingress_tls.k8s.release_name_cert_manager, null)
  issuer_name                = try(var.ingress_tls.k8s.issuer_name, null)
  values_nginx               = try(var.ingress_tls.k8s.values_nginx, {})
  values_cert_manager        = try(var.ingress_tls.k8s.values_cert_manager, {})
  acme_environment           = try(var.ingress_tls.k8s.acme_environment, "production")
  kubeconfig_path            = module.k8s_cluster.kubeconfig_path
  dns_context = {
    hostname          = try(module.dns.hostname, null)
    wildcard_hostname = try(module.dns.wildcard_hostname, null)
  }
  acme_email_candidates = [
    for candidate in compact([
      try(var.ingress_tls.k8s.acme_email, null),
      var.license_email
    ]) : trimspace(candidate)
    if trimspace(candidate) != ""
  ]
  base_domain = var.base_domain

  # Pass Route53 zone ID for DNS-01 challenges when using AWS DNS
  route53_zone_id                 = module.dns.route53_zone_id
  aws_region                      = try(var.object_storage.region, "eu-central-1")
  route53_credentials_secret_name = try(var.ingress_tls.k8s.route53_credentials_secret_name, null)
  aws_access_key_id               = var.aws_access_key_id
  aws_secret_access_key           = var.aws_secret_access_key
  acme_email                      = try(var.ingress_tls.k8s.acme_email, null)
  default_certificate             = try(var.ingress_tls.k8s.default_certificate, null)
  load_balancer_service_name      = try(var.ingress_tls.k8s.load_balancer_service_name, null)
  load_balancer_tags              = try(var.ingress_tls.k8s.load_balancer_tags, {})
  lookup_load_balancer            = local.ingress_lb_lookup_enabled
  cluster_name                    = module.k8s_cluster.cluster_name
}

module "postgres" {
  source = "./deps/postgres"

  mode = try(var.postgres.mode, "k8s")
  namespace = try(
    kubernetes_namespace.deps[local.namespaces.postgres].metadata[0].name,
    local.namespaces.postgres
  )
  manage_namespace = false
  k8s              = try(var.postgres.k8s, {})
  aws              = try(var.postgres.aws, {})
  aws_network      = length(module.cloud_aws) > 0 ? try(module.cloud_aws[0].dependency_context.postgres, {}) : {}
  secrets = {
    password = var.postgres_password
  }
  azure = try(var.postgres.azure, {})
  gcp   = try(var.postgres.gcp, {})
  byo   = try(var.postgres.byo, null)
}

module "redis" {
  source = "./deps/redis"

  mode = try(var.redis.mode, "k8s")
  namespace = try(
    kubernetes_namespace.deps[local.namespaces.redis].metadata[0].name,
    local.namespaces.redis
  )
  manage_namespace = false
  k8s              = try(var.redis.k8s, {})
  aws              = try(var.redis.aws, {})
  aws_network      = length(module.cloud_aws) > 0 ? try(module.cloud_aws[0].dependency_context.redis, {}) : {}
  secrets = {
    password = var.redis_password
  }
  azure = try(var.redis.azure, {})
  gcp   = try(var.redis.gcp, {})
  byo   = try(var.redis.byo, null)
}

module "object_storage" {
  source = "./deps/object_storage"

  mode = try(var.object_storage.mode, "k8s")
  namespace = try(
    kubernetes_namespace.deps[local.namespaces.object_storage].metadata[0].name,
    local.namespaces.object_storage
  )
  manage_namespace = false
  base_domain      = var.base_domain
  k8s              = try(var.object_storage.k8s, {})
  aws              = try(var.object_storage.aws, {})
  azure            = try(var.object_storage.azure, {})
  gcp              = try(var.object_storage.gcp, {})
  byo              = try(var.object_storage.byo, null)
  secrets = {
    access_key = var.object_storage_access_key
    secret_key = var.object_storage_secret_key
  }
}

locals {
  dns_mode        = try(var.dns.mode, "byo")
  ingress_lb_info = try(module.ingress_tls.load_balancer, null)
  ingress_lb_hostname = local.ingress_lb_info == null ? null : coalesce(
    try(local.ingress_lb_info.hostname, null),
    try(local.ingress_lb_info.dns_name, null)
  )
  ingress_lb_dns_name         = try(local.ingress_lb_info.dns_name, local.ingress_lb_hostname)
  ingress_lb_zone_id          = try(local.ingress_lb_info.zone_id, null)
  dns_aws_base_config         = local.dns_mode == "aws" ? try(var.dns.aws, null) : null
  dns_existing_alias          = local.dns_aws_base_config == null ? null : try(local.dns_aws_base_config.alias, null)
  dns_existing_wildcard_alias = local.dns_aws_base_config == null ? null : try(local.dns_aws_base_config.wildcard_alias, null)
  dns_should_inject_alias     = local.dns_aws_base_config != null && local.ingress_lb_zone_id != null && local.dns_existing_alias == null
  dns_should_inject_wildcard  = local.dns_aws_base_config != null && local.ingress_lb_zone_id != null && local.dns_existing_wildcard_alias == null && try(var.dns.enable_wildcard, true)
  dns_injected_alias = local.dns_should_inject_alias ? {
    name                   = local.ingress_lb_dns_name
    zone_id                = local.ingress_lb_zone_id
    evaluate_target_health = false
  } : null
  dns_alias_config = local.dns_should_inject_alias ? {
    main_record_type  = "A"
    main_record_value = null
    alias             = local.dns_injected_alias
  } : {}
  dns_wildcard_alias_config = local.dns_should_inject_wildcard ? {
    wildcard_record_type  = "A"
    wildcard_record_value = null
    wildcard_alias        = local.dns_injected_alias
  } : {}
  dns_hostname_config = local.dns_aws_base_config != null && !local.dns_should_inject_alias && local.ingress_lb_hostname != null && local.dns_existing_alias == null ? {
    main_record_type  = "CNAME"
    main_record_value = local.ingress_lb_hostname
  } : {}
  dns_wildcard_hostname_config = local.dns_aws_base_config != null && !local.dns_should_inject_wildcard && local.ingress_lb_hostname != null && local.dns_existing_wildcard_alias == null && try(var.dns.enable_wildcard, true) ? {
    wildcard_record_type  = "CNAME"
    wildcard_record_value = local.ingress_lb_hostname
  } : {}
  dns_aws_config = local.dns_aws_base_config == null ? null : merge(
    local.dns_aws_base_config,
    local.dns_hostname_config,
    local.dns_wildcard_hostname_config,
    local.dns_alias_config,
    local.dns_wildcard_alias_config
  )
}

module "dns" {
  source = "./deps/dns"

  mode                    = local.dns_mode
  domain                  = coalesce(try(var.dns.domain, null), var.base_domain)
  release_name            = var.btp.release_name
  enable_wildcard         = coalesce(try(var.dns.enable_wildcard, null), true)
  include_wildcard_in_tls = coalesce(try(var.dns.include_wildcard_in_tls, null), try(var.dns.enable_wildcard, null), false)
  cert_manager_issuer     = try(var.dns.cert_manager_issuer, null)
  tls_secret_name         = try(var.dns.tls_secret_name, null)
  ssl_redirect            = coalesce(try(var.dns.ssl_redirect, null), false)
  annotations             = try(var.dns.annotations, {})
  aws                     = local.dns_aws_config
  azure                   = try(var.dns.azure, null)
  gcp                     = try(var.dns.gcp, null)
  cf                      = try(var.dns.cf, null)
  byo                     = try(var.dns.byo, null)
}

module "metrics_logs" {
  source = "./deps/metrics_logs"

  mode = try(var.metrics_logs.mode, "k8s")
  namespace = try(
    kubernetes_namespace.deps[local.namespaces.metrics_logs].metadata[0].name,
    local.namespaces.metrics_logs
  )
  manage_namespace         = false
  kp_stack_chart_version   = try(var.metrics_logs.k8s.kp_stack_chart_version, null)
  loki_stack_chart_version = try(var.metrics_logs.k8s.loki_stack_chart_version, null)
  release_name_kps         = try(var.metrics_logs.k8s.release_name_kps, null)
  release_name_loki        = try(var.metrics_logs.k8s.release_name_loki, null)
  values                   = try(var.metrics_logs.k8s.values, {})
  grafana_password         = var.grafana_admin_password
}

module "oauth" {
  count  = local.oauth_enabled ? 1 : 0
  source = "./deps/oauth"

  mode = try(var.oauth.mode, "k8s")
  namespace = try(
    kubernetes_namespace.deps[local.namespaces.oauth].metadata[0].name,
    local.namespaces.oauth
  )
  manage_namespace = false
  base_domain      = var.base_domain
  k8s              = try(var.oauth.k8s, {})
  aws              = try(var.oauth.aws, {})
  azure            = try(var.oauth.azure, {})
  gcp              = try(var.oauth.gcp, {})
  byo              = try(var.oauth.byo, null)
  secrets = {
    admin_password = var.oauth_admin_password
  }

  depends_on = [module.ingress_tls]
}

module "secrets" {
  source = "./deps/secrets"

  mode = try(var.secrets.mode, "k8s")
  namespace = try(
    kubernetes_namespace.deps[local.namespaces.secrets].metadata[0].name,
    local.namespaces.secrets
  )
  manage_namespace = false
  k8s              = try(var.secrets.k8s, {})
  aws              = try(var.secrets.aws, {})
  azure            = try(var.secrets.azure, {})
  gcp              = try(var.secrets.gcp, {})
  byo              = try(var.secrets.byo, null)
}

# BTP Platform module - deploys the SettleMint Helm chart
# Dynamically injects dependency connection details (postgres, redis, s3, vault, oauth)
# Works across all cloud providers (aws/azure/gcp/k8s/byo) without code changes
module "btp" {
  count  = var.btp.enabled ? 1 : 0
  source = "./btp"

  chart                = var.btp.chart
  chart_version        = var.btp.chart_version
  namespace            = var.btp.namespace
  deployment_namespace = var.btp.deployment_namespace
  release_name         = var.btp.release_name
  values               = var.btp.values
  values_file          = var.btp.values_file
  create_namespace     = true

  base_domain = var.base_domain

  # Pass normalized dependency outputs (works for all modes: aws/azure/gcp/k8s/byo)
  postgres       = module.postgres
  redis          = module.redis
  object_storage = module.object_storage
  oauth          = local.oauth_outputs
  secrets        = module.secrets
  ingress_tls    = module.ingress_tls
  metrics_logs   = module.metrics_logs
  dns            = module.dns

  # License configuration
  license_username        = var.license_username
  license_password        = var.license_password
  license_signature       = var.license_signature
  license_email           = var.license_email
  license_expiration_date = var.license_expiration_date

  # Platform security secrets
  jwt_signing_key       = var.jwt_signing_key
  ipfs_cluster_secret   = var.ipfs_cluster_secret
  state_encryption_key  = var.state_encryption_key
  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key

  # Google OAuth (temporary - for AWS + Google auth setup)
  google_oauth_client_id     = var.google_oauth_client_id
  google_oauth_client_secret = var.google_oauth_client_secret

  # Grafana admin password
  grafana_admin_password = var.grafana_admin_password

  depends_on = [
    module.postgres,
    module.redis,
    module.object_storage,
    module.secrets,
    module.ingress_tls,
    module.metrics_logs,
    module.dns
  ]
}
