# Redis dependency module
# Supports multiple deployment modes: k8s | aws | azure | gcp | byo

locals {
  mode = var.mode

  # Normalize outputs from whichever provider is active
  host = (
    local.mode == "k8s" ? local.k8s_host :
    local.mode == "aws" ? local.aws_host :
    local.mode == "azure" ? local.azure_host :
    local.mode == "gcp" ? local.gcp_host :
    local.mode == "byo" ? local.byo_host :
    null
  )

  port = (
    local.mode == "k8s" ? local.k8s_port :
    local.mode == "aws" ? local.aws_port :
    local.mode == "azure" ? local.azure_port :
    local.mode == "gcp" ? local.gcp_port :
    local.mode == "byo" ? local.byo_port :
    null
  )

  password = (
    local.mode == "k8s" ? local.k8s_password :
    local.mode == "aws" ? local.aws_password :
    local.mode == "azure" ? local.azure_password :
    local.mode == "gcp" ? local.gcp_password :
    local.mode == "byo" ? local.byo_password :
    null
  )

  scheme = (
    local.mode == "k8s" ? local.k8s_scheme :
    local.mode == "aws" ? local.aws_scheme :
    local.mode == "azure" ? local.azure_scheme :
    local.mode == "gcp" ? local.gcp_scheme :
    local.mode == "byo" ? local.byo_scheme :
    null
  )

  tls_enabled = (
    local.mode == "k8s" ? local.k8s_tls_enabled :
    local.mode == "aws" ? local.aws_tls_enabled :
    local.mode == "azure" ? local.azure_tls_enabled :
    local.mode == "gcp" ? local.gcp_tls_enabled :
    local.mode == "byo" ? local.byo_tls_enabled :
    null
  )
}
