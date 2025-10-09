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