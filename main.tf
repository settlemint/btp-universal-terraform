locals {
  ns_ingress     = coalesce(try(var.ingress_tls.k8s.namespace, null), var.namespaces.ingress_tls, "btp-deps")
  ns_postgres    = coalesce(try(var.postgres.k8s.namespace, null), var.namespaces.postgres, "btp-deps")
  ns_redis       = coalesce(try(var.redis.k8s.namespace, null), var.namespaces.redis, "btp-deps")
  ns_minio       = coalesce(try(var.object_storage.k8s.namespace, null), var.namespaces.object_storage, "btp-deps")
  ns_metrics     = coalesce(try(var.metrics_logs.k8s.namespace, null), var.namespaces.metrics_logs, "btp-deps")
  ns_oauth       = coalesce(try(var.oauth.k8s.namespace, null), var.namespaces.oauth, "btp-deps")
  ns_secrets     = coalesce(try(var.secrets.k8s.namespace, null), var.namespaces.secrets, "btp-deps")
  dep_namespaces = toset([local.ns_ingress, local.ns_postgres, local.ns_redis, local.ns_minio, local.ns_metrics, local.ns_oauth, local.ns_secrets])
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
}

module "postgres" {
  source = "./deps/postgres"

  mode             = try(var.postgres.mode, "k8s")
  namespace        = local.ns_postgres
  manage_namespace = false
  chart_version    = try(var.postgres.k8s.chart_version, null)
  release_name     = try(var.postgres.k8s.release_name, null)
  values           = try(var.postgres.k8s.values, {})
  database         = try(var.postgres.k8s.database, null)
}

module "redis" {
  source = "./deps/redis"

  mode             = try(var.redis.mode, "k8s")
  namespace        = local.ns_redis
  manage_namespace = false
  chart_version    = try(var.redis.k8s.chart_version, null)
  release_name     = try(var.redis.k8s.release_name, null)
  values           = try(var.redis.k8s.values, {})
}

module "object_storage" {
  source = "./deps/object_storage"

  mode             = try(var.object_storage.mode, "k8s")
  namespace        = local.ns_minio
  manage_namespace = false
  chart_version    = try(var.object_storage.k8s.chart_version, null)
  release_name     = try(var.object_storage.k8s.release_name, null)
  values           = try(var.object_storage.k8s.values, {})
  default_bucket   = try(var.object_storage.k8s.default_bucket, null)
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
  source = "./deps/oauth"

  mode             = try(var.oauth.mode, "k8s")
  namespace        = local.ns_oauth
  manage_namespace = false
  chart_version    = try(var.oauth.k8s.chart_version, null)
  release_name     = try(var.oauth.k8s.release_name, null)
  values           = try(var.oauth.k8s.values, {})
  base_domain      = var.base_domain
}

module "secrets" {
  source = "./deps/secrets"

  mode             = try(var.secrets.mode, "k8s")
  namespace        = local.ns_secrets
  manage_namespace = false
  chart_version    = try(var.secrets.k8s.chart_version, null)
  release_name     = try(var.secrets.k8s.release_name, null)
  values           = try(var.secrets.k8s.values, {})
  dev_mode         = try(var.secrets.k8s.dev_mode, true)
}
