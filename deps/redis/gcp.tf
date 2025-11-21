# GCP mode: Deploy Redis via Memorystore

locals {
  resolved_gcp_password = coalesce(
    try(var.gcp.auth_string, null),
    try(var.secrets.password, null)
  )

  gcp_config = merge(
    var.gcp,
    {
      auth_string = local.resolved_gcp_password
    }
  )
}

# Memorystore Redis instance
resource "google_redis_instance" "redis" {
  count              = var.mode == "gcp" ? 1 : 0
  project            = local.gcp_config.project_id
  name               = local.gcp_config.instance_name
  tier               = local.gcp_config.tier
  memory_size_gb     = local.gcp_config.memory_size_gb
  region             = local.gcp_config.region
  redis_version      = local.gcp_config.redis_version
  display_name       = local.gcp_config.display_name
  reserved_ip_range  = local.gcp_config.reserved_ip_range
  authorized_network = local.gcp_config.authorized_network

  # Auth configuration
  auth_enabled = local.gcp_config.auth_enabled

  # Transit encryption
  transit_encryption_mode = local.gcp_config.transit_encryption_mode

  # Persistence configuration (STANDARD tier only)
  dynamic "persistence_config" {
    for_each = local.gcp_config.tier == "STANDARD_HA" ? [1] : []
    content {
      persistence_mode    = local.gcp_config.persistence_mode
      rdb_snapshot_period = local.gcp_config.rdb_snapshot_period
    }
  }

  # Maintenance policy
  maintenance_policy {
    weekly_maintenance_window {
      day = local.gcp_config.maintenance_window_day
      start_time {
        hours   = local.gcp_config.maintenance_window_hour
        minutes = 0
        seconds = 0
        nanos   = 0
      }
    }
  }

  # Redis configurations
  redis_configs = local.gcp_config.redis_configs

  labels = merge(
    {
      managed_by = "terraform"
      service    = "redis"
    },
    local.gcp_config.labels
  )
}

locals {
  gcp_host        = var.mode == "gcp" ? google_redis_instance.redis[0].host : null
  gcp_port        = var.mode == "gcp" ? google_redis_instance.redis[0].port : null
  gcp_password    = var.mode == "gcp" && local.gcp_config.auth_enabled ? google_redis_instance.redis[0].auth_string : null
  gcp_scheme      = var.mode == "gcp" ? "redis" : null
  gcp_tls_enabled = var.mode == "gcp" ? local.gcp_config.transit_encryption_mode == "SERVER_AUTHENTICATION" : null
}
