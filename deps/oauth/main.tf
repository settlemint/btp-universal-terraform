# OAuth dependency module
# Supports multiple deployment modes: k8s | aws | azure | gcp | byo

locals {
  mode = var.mode

  # Map-based approach for cleaner conditional logic
  outputs_by_mode = {
    k8s = {
      issuer        = local.k8s_issuer
      admin_url     = local.k8s_admin_url
      client_id     = local.k8s_client_id
      client_secret = local.k8s_client_secret
      scopes        = local.k8s_scopes
      callback_urls = local.k8s_callback_urls
    }
    aws = {
      issuer        = local.aws_issuer
      admin_url     = local.aws_admin_url
      client_id     = local.aws_client_id
      client_secret = local.aws_client_secret
      scopes        = local.aws_scopes
      callback_urls = local.aws_callback_urls
    }
    azure = {
      issuer        = local.azure_issuer
      admin_url     = local.azure_admin_url
      client_id     = local.azure_client_id
      client_secret = local.azure_client_secret
      scopes        = local.azure_scopes
      callback_urls = local.azure_callback_urls
    }
    gcp = {
      issuer        = local.gcp_issuer
      admin_url     = local.gcp_admin_url
      client_id     = local.gcp_client_id
      client_secret = local.gcp_client_secret
      scopes        = local.gcp_scopes
      callback_urls = local.gcp_callback_urls
    }
    byo = {
      issuer        = local.byo_issuer
      admin_url     = local.byo_admin_url
      client_id     = local.byo_client_id
      client_secret = local.byo_client_secret
      scopes        = local.byo_scopes
      callback_urls = local.byo_callback_urls
    }
  }

  # Normalize outputs from whichever provider is active
  outputs       = lookup(local.outputs_by_mode, local.mode, {})
  issuer        = try(local.outputs.issuer, null)
  admin_url     = try(local.outputs.admin_url, null)
  client_id     = try(local.outputs.client_id, null)
  client_secret = try(local.outputs.client_secret, null)
  scopes        = try(local.outputs.scopes, null)
  callback_urls = try(local.outputs.callback_urls, null)
}
