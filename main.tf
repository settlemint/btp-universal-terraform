locals {
  ns_ingress     = coalesce(try(var.ingress_tls.k8s.namespace, null), var.namespaces.ingress_tls, "btp-deps")
  ns_postgres    = coalesce(try(var.postgres.k8s.namespace, null), var.namespaces.postgres, "btp-deps")
  ns_redis       = coalesce(try(var.redis.k8s.namespace, null), var.namespaces.redis, "btp-deps")
  ns_minio       = coalesce(try(var.object_storage.k8s.namespace, null), var.namespaces.object_storage, "btp-deps")
  ns_metrics     = coalesce(try(var.metrics_logs.k8s.namespace, null), var.namespaces.metrics_logs, "btp-deps")
  ns_oauth       = coalesce(try(var.oauth.k8s.namespace, null), var.namespaces.oauth, "btp-deps")
  ns_secrets     = coalesce(try(var.secrets.k8s.namespace, null), var.namespaces.secrets, "btp-deps")
  dep_namespaces = try(var.oauth.mode, "disabled") == "disabled" ? toset([local.ns_ingress, local.ns_postgres, local.ns_redis, local.ns_minio, local.ns_metrics, local.ns_secrets]) : toset([local.ns_ingress, local.ns_postgres, local.ns_redis, local.ns_minio, local.ns_metrics, local.ns_oauth, local.ns_secrets])
}

resource "kubernetes_namespace" "deps" {
  for_each = local.dep_namespaces
  metadata {
    name = each.value
    labels = {
      "btp.smint.io/platform" = var.platform
    }
  }
}

module "ingress_tls" {
  source = "./deps/ingress_tls"

  mode                       = try(var.ingress_tls.mode, "k8s")
  namespace                  = local.ns_ingress
  manage_namespace           = false
  nginx_chart_version        = try(var.ingress_tls.k8s.nginx_chart_version, null)
  cert_manager_chart_version = try(var.ingress_tls.k8s.cert_manager_chart_version, null)
  release_name_nginx         = try(var.ingress_tls.k8s.release_name_nginx, null)
  release_name_cert_manager  = try(var.ingress_tls.k8s.release_name_cert_manager, null)
  issuer_name                = try(var.ingress_tls.k8s.issuer_name, null)
  values_nginx               = try(var.ingress_tls.k8s.values_nginx, {})
  values_cert_manager        = try(var.ingress_tls.k8s.values_cert_manager, {})
}

module "postgres" {
  source = "./deps/postgres"

  mode             = try(var.postgres.mode, "k8s")
  namespace        = local.ns_postgres
  manage_namespace = false
  k8s              = try(var.postgres.k8s, {})
  aws              = try(var.postgres.aws, {})
  azure            = try(var.postgres.azure, {})
  gcp              = try(var.postgres.gcp, {})
  byo              = try(var.postgres.byo, null)
}

module "redis" {
  source = "./deps/redis"

  mode             = try(var.redis.mode, "k8s")
  namespace        = local.ns_redis
  manage_namespace = false
  k8s              = try(var.redis.k8s, {})
  aws              = try(var.redis.aws, {})
  azure            = try(var.redis.azure, {})
  gcp              = try(var.redis.gcp, {})
  byo              = try(var.redis.byo, null)
}

module "object_storage" {
  source = "./deps/object_storage"

  mode             = try(var.object_storage.mode, "k8s")
  namespace        = local.ns_minio
  manage_namespace = false
  k8s              = try(var.object_storage.k8s, {})
  aws              = try(var.object_storage.aws, {})
  azure            = try(var.object_storage.azure, {})
  gcp              = try(var.object_storage.gcp, {})
  byo              = try(var.object_storage.byo, null)
}

module "metrics_logs" {
  source = "./deps/metrics_logs"

  mode                     = try(var.metrics_logs.mode, "k8s")
  namespace                = local.ns_metrics
  manage_namespace         = false
  kp_stack_chart_version   = try(var.metrics_logs.k8s.kp_stack_chart_version, null)
  loki_stack_chart_version = try(var.metrics_logs.k8s.loki_stack_chart_version, null)
  release_name_kps         = try(var.metrics_logs.k8s.release_name_kps, null)
  release_name_loki        = try(var.metrics_logs.k8s.release_name_loki, null)
  values                   = try(var.metrics_logs.k8s.values, {})
}

module "oauth" {
  count  = try(var.oauth.mode, "disabled") != "disabled" ? 1 : 0
  source = "./deps/oauth"

  mode             = try(var.oauth.mode, "k8s")
  namespace        = local.ns_oauth
  manage_namespace = false
  base_domain      = var.base_domain
  k8s              = try(var.oauth.k8s, {})
  aws              = try(var.oauth.aws, {})
  azure            = try(var.oauth.azure, {})
  gcp              = try(var.oauth.gcp, {})
  byo              = try(var.oauth.byo, null)

  depends_on = [module.ingress_tls]
}

module "secrets" {
  source = "./deps/secrets"

  mode             = try(var.secrets.mode, "k8s")
  namespace        = local.ns_secrets
  manage_namespace = false
  k8s              = try(var.secrets.k8s, {})
  aws              = try(var.secrets.aws, {})
  azure            = try(var.secrets.azure, {})
  gcp              = try(var.secrets.gcp, {})
  byo              = try(var.secrets.byo, null)
}

# BTP Platform module - temporarily disabled
# REASON: Terraform shallow merge() is causing values from enhanced-dev-values.yaml to override
# critical nested fields (state.credentials, targets array) from dev_defaults in btp/main.tf.
# This results in undefined AWS credentials and missing deployment targets, causing ZodError crashes.
# Need to either implement deep merge function or restructure how values are passed to Helm.
# For now, only deploy dependencies (postgres, redis, ingress, etc.) to unblock other work.

# module "btp" {
#   count  = var.btp.enabled ? 1 : 0
#   source = "./btp"
#
#   chart            = var.btp.chart
#   chart_version    = var.btp.chart_version
#   namespace        = var.btp.namespace
#   release_name     = var.btp.release_name
#   values           = var.btp.values
#   values_file      = var.btp.values_file
#   create_namespace = true
#
#   base_domain = var.base_domain
#
#   # Pass dependency outputs
#   postgres       = module.postgres
#   redis          = module.redis
#   object_storage = module.object_storage
#   oauth          = try(var.oauth.mode, "disabled") == "disabled" ? {} : (length(module.oauth) > 0 ? module.oauth[0] : {})
#   secrets        = module.secrets
#   ingress_tls    = module.ingress_tls
#   metrics_logs   = module.metrics_logs
#
#   # License configuration
#   license_username         = var.license_username
#   license_password         = var.license_password
#   license_signature        = var.license_signature
#   license_email            = var.license_email
#   license_expiration_date  = var.license_expiration_date
#
#   # Platform security secrets
#   jwt_signing_key       = var.jwt_signing_key
#   ipfs_cluster_secret   = var.ipfs_cluster_secret
#   state_encryption_key  = var.state_encryption_key
#   aws_access_key_id     = var.aws_access_key_id
#   aws_secret_access_key = var.aws_secret_access_key
#
#   depends_on = [
#     module.postgres,
#     module.redis,
#     module.object_storage,
#     module.secrets,
#     module.ingress_tls,
#     module.metrics_logs
#   ]
# }
