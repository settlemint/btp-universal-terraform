# BYO mode: Bring-your-own PostgreSQL (external endpoint)
# No resources created, just pass through user-provided credentials

locals {
  byo_host     = var.mode == "byo" ? var.byo.host : null
  byo_port     = var.mode == "byo" ? var.byo.port : null
  byo_user     = var.mode == "byo" ? var.byo.username : null
  byo_password = var.mode == "byo" ? var.byo.password : null
  byo_database = var.mode == "byo" ? var.byo.database : null
  byo_ssl_mode = var.mode == "byo" ? try(var.byo.ssl_mode, "disable") : null
}
