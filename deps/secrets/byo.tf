# BYO mode: Bring-your-own Vault/secrets service
# No resources created, just pass through user-provided configuration

locals {
  byo_vault_addr = var.mode == "byo" ? var.byo.vault_addr : null
  byo_token      = var.mode == "byo" ? var.byo.token : null
  byo_kv_mount   = var.mode == "byo" ? var.byo.kv_mount : null
  byo_paths      = var.mode == "byo" ? var.byo.paths : null
}
