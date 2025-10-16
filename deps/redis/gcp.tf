# GCP mode: Deploy Redis via Memorystore
# TODO: Implement GCP Memorystore for Redis

# Placeholder for GCP implementation
# resource "google_redis_instance" "redis" {
#   count          = var.mode == "gcp" ? 1 : 0
#   name           = var.gcp.instance_name
#   tier           = var.gcp.tier
#   memory_size_gb = var.gcp.memory_size_gb
#   region         = var.gcp.region
#   redis_version  = var.gcp.redis_version
# }

locals {
  gcp_host        = var.mode == "gcp" ? "memorystore-instance-ip" : null
  gcp_port        = var.mode == "gcp" ? 6379 : null
  gcp_password    = var.mode == "gcp" ? var.gcp.auth_string : null
  gcp_scheme      = var.mode == "gcp" ? "redis" : null
  gcp_tls_enabled = var.mode == "gcp" ? var.gcp.transit_encryption_mode == "SERVER_AUTHENTICATION" : null
}
