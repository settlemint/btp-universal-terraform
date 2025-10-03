# Object Storage dependency module
# Supports multiple deployment modes: k8s | aws | azure | gcp | byo

locals {
  mode = var.mode

  # Normalize outputs from whichever provider is active
  endpoint = (
    local.mode == "k8s" ? local.k8s_endpoint :
    local.mode == "aws" ? local.aws_endpoint :
    local.mode == "azure" ? local.azure_endpoint :
    local.mode == "gcp" ? local.gcp_endpoint :
    local.mode == "byo" ? local.byo_endpoint :
    null
  )

  bucket = (
    local.mode == "k8s" ? local.k8s_bucket :
    local.mode == "aws" ? local.aws_bucket :
    local.mode == "azure" ? local.azure_bucket :
    local.mode == "gcp" ? local.gcp_bucket :
    local.mode == "byo" ? local.byo_bucket :
    null
  )

  access_key = (
    local.mode == "k8s" ? local.k8s_access_key :
    local.mode == "aws" ? local.aws_access_key :
    local.mode == "azure" ? local.azure_access_key :
    local.mode == "gcp" ? local.gcp_access_key :
    local.mode == "byo" ? local.byo_access_key :
    null
  )

  secret_key = (
    local.mode == "k8s" ? local.k8s_secret_key :
    local.mode == "aws" ? local.aws_secret_key :
    local.mode == "azure" ? local.azure_secret_key :
    local.mode == "gcp" ? local.gcp_secret_key :
    local.mode == "byo" ? local.byo_secret_key :
    null
  )

  region = (
    local.mode == "k8s" ? local.k8s_region :
    local.mode == "aws" ? local.aws_region :
    local.mode == "azure" ? local.azure_region :
    local.mode == "gcp" ? local.gcp_region :
    local.mode == "byo" ? local.byo_region :
    null
  )

  use_path_style = (
    local.mode == "k8s" ? local.k8s_use_path_style :
    local.mode == "aws" ? local.aws_use_path_style :
    local.mode == "azure" ? local.azure_use_path_style :
    local.mode == "gcp" ? local.gcp_use_path_style :
    local.mode == "byo" ? local.byo_use_path_style :
    null
  )
}
