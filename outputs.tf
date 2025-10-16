output "postgres" {
  description = "PostgreSQL connection details including host, port, credentials, and database name"
  value = {
    connection_string = module.postgres.connection_string
    host              = module.postgres.host
    port              = module.postgres.port
    username          = module.postgres.username
    password          = module.postgres.password
    database          = module.postgres.database
  }
  sensitive = true
}

output "redis" {
  description = "Redis connection details including host, port, password, and TLS configuration"
  value = {
    host        = module.redis.host
    port        = module.redis.port
    password    = module.redis.password
    scheme      = module.redis.scheme
    tls_enabled = module.redis.tls_enabled
  }
  sensitive = true
}

output "object_storage" {
  description = "Object storage (S3/MinIO/etc) connection details including endpoint, bucket, and credentials"
  value = {
    endpoint       = module.object_storage.endpoint
    bucket         = module.object_storage.bucket
    access_key     = module.object_storage.access_key
    secret_key     = module.object_storage.secret_key
    region         = module.object_storage.region
    use_path_style = module.object_storage.use_path_style
  }
  sensitive = true
}

output "oauth" {
  description = "OAuth/OIDC provider configuration including issuer, client credentials, and endpoints"
  value = length(module.oauth) > 0 ? {
    issuer        = module.oauth[0].issuer
    admin_url     = module.oauth[0].admin_url
    client_id     = module.oauth[0].client_id
    client_secret = module.oauth[0].client_secret
    scopes        = module.oauth[0].scopes
    callback_urls = module.oauth[0].callback_urls
    } : {
    issuer        = null
    admin_url     = null
    client_id     = null
    client_secret = null
    scopes        = []
    callback_urls = []
  }
  sensitive = true
}

output "secrets" {
  description = "Secrets manager (Vault/etc) configuration including address, token, and mount paths"
  value = {
    vault_addr = module.secrets.vault_addr
    token      = module.secrets.token
    kv_mount   = module.secrets.kv_mount
    paths      = module.secrets.paths
  }
  sensitive = true
}

output "ingress_tls" {
  description = "Ingress and TLS configuration including ingress class and cert-manager issuer"
  value = {
    ingress_class = module.ingress_tls.ingress_class
    issuer_name   = module.ingress_tls.issuer_name
  }
}

output "dns" {
  description = "DNS automation outputs including managed records and ingress hints"
  value = {
    hostname            = module.dns.hostname
    wildcard_hostname   = module.dns.wildcard_hostname
    tls_secret_name     = module.dns.tls_secret_name
    tls_hosts           = module.dns.tls_hosts
    ingress_annotations = module.dns.ingress_annotations
    ssl_redirect        = module.dns.ssl_redirect
    records             = module.dns.records
  }
}

locals {
  summary_platform_hostname      = coalesce(module.dns.hostname, coalesce(var.base_domain, "btp.local"))
  summary_platform_url           = format("https://%s", local.summary_platform_hostname)
  summary_grafana_raw            = try(module.metrics_logs.grafana_url, "")
  summary_grafana_url            = length(trimspace(local.summary_grafana_raw)) > 0 ? local.summary_grafana_raw : format("https://grafana.%s", local.summary_platform_hostname)
  summary_object_storage_console = try(var.object_storage.mode, "k8s") == "aws" && module.object_storage.region != null ? format("https://s3.console.aws.amazon.com/s3/buckets/%s?region=%s", module.object_storage.bucket, module.object_storage.region) : null
  summary_postgres_endpoint      = format("%s:%s (db=%s)", module.postgres.host, module.postgres.port, module.postgres.database)
  summary_redis_endpoint         = format("%s:%s (tls=%s)", module.redis.host, module.redis.port, module.redis.tls_enabled)
  summary_oauth_issuer           = length(module.oauth) > 0 ? module.oauth[0].issuer : null
  summary_metrics_endpoints = [
    try(module.metrics_logs.prometheus_endpoint, null),
    try(module.metrics_logs.loki_endpoint, null)
  ]
  summary_object_storage_line = local.summary_object_storage_console != null ? format("Object Storage (AWS console) → %s", local.summary_object_storage_console) : format("Object Storage endpoint → %s (bucket=%s)", module.object_storage.endpoint, module.object_storage.bucket)
  summary_lines = compact(concat(
    [
      format("SettleMint Platform → %s", local.summary_platform_url),
      format("Grafana (user=%s) → %s", module.metrics_logs.grafana_username, local.summary_grafana_url),
      format("PostgreSQL → %s", local.summary_postgres_endpoint),
      format("Redis → %s", local.summary_redis_endpoint),
      local.summary_object_storage_line
    ],
    local.summary_oauth_issuer != null ? [format("OAuth issuer → %s", local.summary_oauth_issuer)] : [],
    [for endpoint in local.summary_metrics_endpoints : format("Observability endpoint → %s", endpoint) if endpoint != null]
  ))
}

output "post_deploy_urls" {
  description = "Key endpoints to verify after deployment."
  value = {
    platform_url               = local.summary_platform_url
    grafana_url                = local.summary_grafana_url
    grafana_username           = module.metrics_logs.grafana_username
    postgres_endpoint          = local.summary_postgres_endpoint
    redis_endpoint             = local.summary_redis_endpoint
    object_storage_console_url = local.summary_object_storage_console
    object_storage_endpoint    = module.object_storage.endpoint
    object_storage_bucket      = module.object_storage.bucket
    oauth_issuer               = local.summary_oauth_issuer
    prometheus_endpoint        = try(module.metrics_logs.prometheus_endpoint, null)
    loki_endpoint              = try(module.metrics_logs.loki_endpoint, null)
  }
}

output "post_deploy_message" {
  description = "Human-readable summary of endpoints to test post deployment."
  value       = join("\n", local.summary_lines)
}

output "metrics_logs" {
  description = "Observability endpoints for Prometheus, Loki, and Grafana including credentials"
  value = {
    prometheus_endpoint = module.metrics_logs.prometheus_endpoint
    loki_endpoint       = module.metrics_logs.loki_endpoint
    grafana_url         = module.metrics_logs.grafana_url
    grafana_username    = module.metrics_logs.grafana_username
    grafana_password    = module.metrics_logs.grafana_password
  }
  sensitive = true
}

output "k8s_cluster" {
  description = "Kubernetes cluster details including endpoint, version, and cloud provider-specific information"
  value = {
    cluster_name     = module.k8s_cluster.cluster_name
    cluster_endpoint = module.k8s_cluster.cluster_endpoint
    cluster_version  = module.k8s_cluster.cluster_version
    mode             = module.k8s_cluster.mode
    kubeconfig       = module.k8s_cluster.kubeconfig
    # AWS-specific
    aws_oidc_provider_arn = module.k8s_cluster.aws_oidc_provider_arn
    aws_oidc_provider_url = module.k8s_cluster.aws_oidc_provider_url
    # Azure-specific
    azure_cluster_id = module.k8s_cluster.azure_cluster_id
    # GCP-specific
    gcp_cluster_id = module.k8s_cluster.gcp_cluster_id
  }
  sensitive = true
}
