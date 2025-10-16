# PostgreSQL dependency module
# Supports multiple deployment modes: k8s | aws | azure | gcp | byo

locals {
  mode = var.mode

  # Map-based approach for cleaner conditional logic
  outputs_by_mode = {
    k8s = {
      host     = local.k8s_host
      port     = local.k8s_port
      username = local.k8s_user
      password = local.k8s_password
      database = local.k8s_database
    }
    aws = {
      host              = local.aws_host
      port              = local.aws_port
      username          = local.aws_user
      password          = local.aws_password
      database          = local.aws_database
      subnet_group_name = local.aws_subnet_group_name_effective
    }
    azure = {
      host     = local.azure_host
      port     = local.azure_port
      username = local.azure_user
      password = local.azure_password
      database = local.azure_database
    }
    gcp = {
      host     = local.gcp_host
      port     = local.gcp_port
      username = local.gcp_user
      password = local.gcp_password
      database = local.gcp_database
    }
    byo = {
      host     = local.byo_host
      port     = local.byo_port
      username = local.byo_user
      password = local.byo_password
      database = local.byo_database
    }
  }

  # Normalize outputs from whichever provider is active
  outputs  = lookup(local.outputs_by_mode, local.mode, {})
  host     = try(local.outputs.host, null)
  port     = try(local.outputs.port, null)
  username = try(local.outputs.username, null)
  password = try(local.outputs.password, null)
  database = try(local.outputs.database, null)

  # Build connection string
  connection_string = local.password != null ? "postgres://${local.username}:${local.password}@${local.host}:${local.port}/${local.database}?sslmode=disable" : ""
}
