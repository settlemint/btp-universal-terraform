# OAuth dependency module
# Supports multiple deployment modes: k8s | aws | azure | gcp | byo

locals {
  mode = var.mode

  # Normalize outputs from whichever provider is active
  issuer = (
    local.mode == "k8s" ? local.k8s_issuer :
    local.mode == "aws" ? local.aws_issuer :
    local.mode == "azure" ? local.azure_issuer :
    local.mode == "gcp" ? local.gcp_issuer :
    local.mode == "byo" ? local.byo_issuer :
    null
  )

  admin_url = (
    local.mode == "k8s" ? local.k8s_admin_url :
    local.mode == "aws" ? local.aws_admin_url :
    local.mode == "azure" ? local.azure_admin_url :
    local.mode == "gcp" ? local.gcp_admin_url :
    local.mode == "byo" ? local.byo_admin_url :
    null
  )

  client_id = (
    local.mode == "k8s" ? local.k8s_client_id :
    local.mode == "aws" ? local.aws_client_id :
    local.mode == "azure" ? local.azure_client_id :
    local.mode == "gcp" ? local.gcp_client_id :
    local.mode == "byo" ? local.byo_client_id :
    null
  )

  client_secret = (
    local.mode == "k8s" ? local.k8s_client_secret :
    local.mode == "aws" ? local.aws_client_secret :
    local.mode == "azure" ? local.azure_client_secret :
    local.mode == "gcp" ? local.gcp_client_secret :
    local.mode == "byo" ? local.byo_client_secret :
    null
  )

  scopes = (
    local.mode == "k8s" ? local.k8s_scopes :
    local.mode == "aws" ? local.aws_scopes :
    local.mode == "azure" ? local.azure_scopes :
    local.mode == "gcp" ? local.gcp_scopes :
    local.mode == "byo" ? local.byo_scopes :
    null
  )

  callback_urls = (
    local.mode == "k8s" ? local.k8s_callback_urls :
    local.mode == "aws" ? local.aws_callback_urls :
    local.mode == "azure" ? local.azure_callback_urls :
    local.mode == "gcp" ? local.gcp_callback_urls :
    local.mode == "byo" ? local.byo_callback_urls :
    null
  )
}
