# GCP mode: Deploy PostgreSQL via Cloud SQL
# TODO: Implement GCP Cloud SQL PostgreSQL instance

# Placeholder for GCP implementation
# resource "google_sql_database_instance" "postgres" {
#   count            = var.mode == "gcp" ? 1 : 0
#   name             = var.gcp.instance_name
#   database_version = var.gcp.database_version
#   region           = var.gcp.region
#
#   settings {
#     tier = var.gcp.tier
#   }
# }

locals {
  gcp_host     = var.mode == "gcp" ? "cloudsql-connection-name" : null
  gcp_port     = var.mode == "gcp" ? 5432 : null
  gcp_user     = var.mode == "gcp" ? var.gcp.username : null
  gcp_password = var.mode == "gcp" ? var.gcp.password : null
  gcp_database = var.mode == "gcp" ? var.gcp.database : null
  gcp_ssl_mode = var.mode == "gcp" ? "require" : null
}
