# PostgreSQL dependency module
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

  username = (
    local.mode == "k8s" ? local.k8s_user :
    local.mode == "aws" ? local.aws_user :
    local.mode == "azure" ? local.azure_user :
    local.mode == "gcp" ? local.gcp_user :
    local.mode == "byo" ? local.byo_user :
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

  database = (
    local.mode == "k8s" ? local.k8s_database :
    local.mode == "aws" ? local.aws_database :
    local.mode == "azure" ? local.azure_database :
    local.mode == "gcp" ? local.gcp_database :
    local.mode == "byo" ? local.byo_database :
    null
  )

  # Build connection string
  connection_string = local.password != null ? "postgres://${local.username}:${local.password}@${local.host}:${local.port}/${local.database}?sslmode=disable" : ""
}
