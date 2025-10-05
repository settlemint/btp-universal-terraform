output "postgres" {
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
  value = {
    vault_addr = module.secrets.vault_addr
    token      = module.secrets.token
    kv_mount   = module.secrets.kv_mount
    paths      = module.secrets.paths
  }
  sensitive = true
}

output "ingress_tls" {
  value = {
    ingress_class = module.ingress_tls.ingress_class
    issuer_name   = module.ingress_tls.issuer_name
  }
}

output "metrics_logs" {
  value = {
    prometheus_endpoint = module.metrics_logs.prometheus_endpoint
    loki_endpoint       = module.metrics_logs.loki_endpoint
    grafana_url         = module.metrics_logs.grafana_url
    grafana_username    = module.metrics_logs.grafana_username
    grafana_password    = module.metrics_logs.grafana_password
  }
  sensitive = true
}

