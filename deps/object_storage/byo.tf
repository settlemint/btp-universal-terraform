# BYO mode: Bring-your-own object storage (S3-compatible endpoint)
# No resources created, just pass through user-provided credentials

locals {
  byo_endpoint       = var.mode == "byo" ? var.byo.endpoint : null
  byo_bucket         = var.mode == "byo" ? var.byo.bucket : null
  byo_access_key     = var.mode == "byo" ? var.byo.access_key : null
  byo_secret_key     = var.mode == "byo" ? var.byo.secret_key : null
  byo_region         = var.mode == "byo" ? var.byo.region : null
  byo_use_path_style = var.mode == "byo" ? var.byo.use_path_style : null
}
