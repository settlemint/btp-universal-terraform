# Redis dependency module
# Supports multiple deployment modes: k8s | aws | azure | gcp | byo

locals {
  mode = var.mode

  # Map-based approach for cleaner conditional logic
  outputs_by_mode = {
    k8s = {
      host        = local.k8s_host
      port        = local.k8s_port
      password    = local.k8s_password
      scheme      = local.k8s_scheme
      tls_enabled = local.k8s_tls_enabled
    }
    aws = {
      host        = local.aws_host
      port        = local.aws_port
      password    = local.aws_password
      scheme      = local.aws_scheme
      tls_enabled = local.aws_tls_enabled
    }
    azure = {
      host        = local.azure_host
      port        = local.azure_port
      password    = local.azure_password
      scheme      = local.azure_scheme
      tls_enabled = local.azure_tls_enabled
    }
    gcp = {
      host        = local.gcp_host
      port        = local.gcp_port
      password    = local.gcp_password
      scheme      = local.gcp_scheme
      tls_enabled = local.gcp_tls_enabled
    }
    byo = {
      host        = local.byo_host
      port        = local.byo_port
      password    = local.byo_password
      scheme      = local.byo_scheme
      tls_enabled = local.byo_tls_enabled
    }
  }

  # Normalize outputs from whichever provider is active
  outputs     = lookup(local.outputs_by_mode, local.mode, {})
  host        = try(local.outputs.host, null)
  port        = try(local.outputs.port, null)
  password    = try(local.outputs.password, null)
  scheme      = try(local.outputs.scheme, null)
  tls_enabled = try(local.outputs.tls_enabled, null)
}
