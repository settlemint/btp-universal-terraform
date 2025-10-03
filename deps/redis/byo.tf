# BYO mode: Bring-your-own Redis (external endpoint)
# No resources created, just pass through user-provided credentials

locals {
  byo_host        = var.mode == "byo" ? var.byo.host : null
  byo_port        = var.mode == "byo" ? var.byo.port : null
  byo_password    = var.mode == "byo" ? var.byo.password : null
  byo_scheme      = var.mode == "byo" ? var.byo.scheme : null
  byo_tls_enabled = var.mode == "byo" ? var.byo.tls_enabled : null
}
