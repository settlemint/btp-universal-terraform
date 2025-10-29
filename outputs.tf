locals {
  summary_platform_hostname = coalesce(module.dns.hostname, coalesce(var.base_domain, "btp.local"))
  summary_platform_url      = format("https://%s", local.summary_platform_hostname)
  summary_postgres_endpoint = format("%s:%s (db=%s)", module.postgres.host, module.postgres.port, module.postgres.database)
  summary_redis_endpoint    = format("%s:%s", module.redis.host, module.redis.port)
  summary_oauth_issuer      = length(module.oauth) > 0 ? module.oauth[0].issuer : null
  summary_lines = compact(concat(
    [
      format("SettleMint Platform → %s", local.summary_platform_url),
      format("PostgreSQL → %s", local.summary_postgres_endpoint),
      format("Redis → %s", local.summary_redis_endpoint),
    ],
  ))
}

output "post_deploy_urls" {
  description = "Key endpoints to verify after deployment."
  value = {
    platform_url      = local.summary_platform_url
    grafana_username  = "admin"
    grafana_url       = format("https://grafana.%s", local.summary_platform_hostname)
    postgres_endpoint = local.summary_postgres_endpoint
    redis_endpoint    = local.summary_redis_endpoint
  }
}


