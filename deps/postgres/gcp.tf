# GCP mode: Deploy PostgreSQL via Cloud SQL

locals {
  resolved_gcp_password = coalesce(
    try(var.gcp.password, null),
    try(var.secrets.password, null)
  )

  gcp_config = merge(
    var.gcp,
    {
      password = local.resolved_gcp_password
    }
  )
}

# Random suffix for Cloud SQL instance name (must be unique globally)
resource "random_id" "cloudsql_suffix" {
  count       = var.mode == "gcp" ? 1 : 0
  byte_length = 4
}

# Cloud SQL PostgreSQL instance
resource "google_sql_database_instance" "postgres" {
  count            = var.mode == "gcp" ? 1 : 0
  project          = local.gcp_config.project_id
  name             = "${local.gcp_config.instance_name}-${random_id.cloudsql_suffix[0].hex}"
  database_version = local.gcp_config.database_version
  region           = local.gcp_config.region

  settings {
    tier              = local.gcp_config.tier
    availability_type = local.gcp_config.availability_type
    disk_type         = local.gcp_config.disk_type
    disk_size         = local.gcp_config.disk_size
    disk_autoresize   = local.gcp_config.disk_autoresize

    backup_configuration {
      enabled                        = local.gcp_config.backup_enabled
      start_time                     = local.gcp_config.backup_start_time
      point_in_time_recovery_enabled = local.gcp_config.point_in_time_recovery_enabled
      transaction_log_retention_days = local.gcp_config.transaction_log_retention_days
      backup_retention_settings {
        retained_backups = local.gcp_config.retained_backups
        retention_unit   = "COUNT"
      }
    }

    ip_configuration {
      ipv4_enabled    = local.gcp_config.ipv4_enabled
      private_network = local.gcp_config.private_network
      ssl_mode        = local.gcp_config.require_ssl ? "ENCRYPTED_ONLY" : "ALLOW_UNENCRYPTED_AND_ENCRYPTED"

      dynamic "authorized_networks" {
        for_each = local.gcp_config.authorized_networks
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.value
        }
      }
    }

    maintenance_window {
      day          = local.gcp_config.maintenance_window_day
      hour         = local.gcp_config.maintenance_window_hour
      update_track = "stable"
    }

    insights_config {
      query_insights_enabled  = local.gcp_config.query_insights_enabled
      query_string_length     = 1024
      record_application_tags = false
      record_client_address   = false
    }

    database_flags {
      name  = "max_connections"
      value = local.gcp_config.max_connections
    }
  }

  deletion_protection = local.gcp_config.deletion_protection
}

# Create database
resource "google_sql_database" "database" {
  count     = var.mode == "gcp" ? 1 : 0
  project   = local.gcp_config.project_id
  name      = local.gcp_config.database
  instance  = google_sql_database_instance.postgres[0].name
  charset   = "UTF8"
  collation = "en_US.UTF8"
}

# Create database user
resource "google_sql_user" "user" {
  count    = var.mode == "gcp" ? 1 : 0
  project  = local.gcp_config.project_id
  name     = local.gcp_config.username
  instance = google_sql_database_instance.postgres[0].name
  password = local.gcp_config.password
}

locals {
  # Connection details for Cloud SQL
  # Use private IP if available, otherwise fall back to public IP
  gcp_host = var.mode == "gcp" ? coalesce(
    google_sql_database_instance.postgres[0].private_ip_address,
    google_sql_database_instance.postgres[0].public_ip_address
  ) : null
  gcp_connection_name = var.mode == "gcp" ? google_sql_database_instance.postgres[0].connection_name : null
  gcp_port            = var.mode == "gcp" ? 5432 : null
  gcp_user            = var.mode == "gcp" ? google_sql_user.user[0].name : null
  gcp_password        = var.mode == "gcp" ? local.gcp_config.password : null
  gcp_database        = var.mode == "gcp" ? google_sql_database.database[0].name : null
}
