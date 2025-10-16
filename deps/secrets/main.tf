# Secrets dependency module
# Supports multiple deployment modes: k8s | aws | azure | gcp | byo

locals {
  mode = var.mode

  # Normalize outputs from whichever provider is active
  vault_addr = (
    local.mode == "k8s" ? local.k8s_vault_addr :
    local.mode == "aws" ? local.aws_vault_addr :
    local.mode == "azure" ? local.azure_vault_addr :
    local.mode == "gcp" ? local.gcp_vault_addr :
    local.mode == "byo" ? local.byo_vault_addr :
    null
  )

  token = (
    local.mode == "k8s" ? local.k8s_token :
    local.mode == "aws" ? local.aws_token :
    local.mode == "azure" ? local.azure_token :
    local.mode == "gcp" ? local.gcp_token :
    local.mode == "byo" ? local.byo_token :
    null
  )

  kv_mount = (
    local.mode == "k8s" ? local.k8s_kv_mount :
    local.mode == "aws" ? local.aws_kv_mount :
    local.mode == "azure" ? local.azure_kv_mount :
    local.mode == "gcp" ? local.gcp_kv_mount :
    local.mode == "byo" ? local.byo_kv_mount :
    null
  )

  paths = (
    local.mode == "k8s" ? local.k8s_paths :
    local.mode == "aws" ? local.aws_paths :
    local.mode == "azure" ? local.azure_paths :
    local.mode == "gcp" ? local.gcp_paths :
    local.mode == "byo" ? local.byo_paths :
    null
  )
}
