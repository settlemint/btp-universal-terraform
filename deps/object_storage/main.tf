# Object Storage dependency module
# Supports multiple deployment modes: k8s | aws | azure | gcp | byo

locals {
  mode = var.mode

  # Map-based approach for cleaner conditional logic
  outputs_by_mode = {
    k8s = {
      endpoint       = local.k8s_endpoint
      bucket         = local.k8s_bucket
      access_key     = local.k8s_access_key
      secret_key     = local.k8s_secret_key
      region         = local.k8s_region
      use_path_style = local.k8s_use_path_style
    }
    aws = {
      endpoint       = local.aws_endpoint
      bucket         = local.aws_bucket
      access_key     = local.aws_access_key
      secret_key     = local.aws_secret_key
      region         = local.aws_region
      use_path_style = local.aws_use_path_style
    }
    azure = {
      endpoint       = local.azure_endpoint
      bucket         = local.azure_bucket
      access_key     = local.azure_access_key
      secret_key     = local.azure_secret_key
      region         = local.azure_region
      use_path_style = local.azure_use_path_style
    }
    gcp = {
      endpoint       = local.gcp_endpoint
      bucket         = local.gcp_bucket
      access_key     = local.gcp_access_key
      secret_key     = local.gcp_secret_key
      region         = local.gcp_region
      use_path_style = local.gcp_use_path_style
    }
    byo = {
      endpoint       = local.byo_endpoint
      bucket         = local.byo_bucket
      access_key     = local.byo_access_key
      secret_key     = local.byo_secret_key
      region         = local.byo_region
      use_path_style = local.byo_use_path_style
    }
  }

  # Normalize outputs from whichever provider is active
  outputs        = lookup(local.outputs_by_mode, local.mode, {})
  endpoint       = try(local.outputs.endpoint, null)
  bucket         = try(local.outputs.bucket, null)
  access_key     = try(local.outputs.access_key, null)
  secret_key     = try(local.outputs.secret_key, null)
  region         = try(local.outputs.region, null)
  use_path_style = try(local.outputs.use_path_style, null)
}
