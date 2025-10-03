# BYO mode: Bring-your-own OAuth/OIDC provider
# No resources created, just pass through user-provided configuration

locals {
  byo_issuer        = var.mode == "byo" ? var.byo.issuer : null
  byo_admin_url     = var.mode == "byo" ? var.byo.admin_url : null
  byo_client_id     = var.mode == "byo" ? var.byo.client_id : null
  byo_client_secret = var.mode == "byo" ? var.byo.client_secret : null
  byo_scopes        = var.mode == "byo" ? var.byo.scopes : null
  byo_callback_urls = var.mode == "byo" ? var.byo.callback_urls : null
}
