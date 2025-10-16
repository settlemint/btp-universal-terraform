# AWS mode: Deploy S3 bucket

locals {
  aws_manage_bucket       = var.mode == "aws" ? try(var.aws.manage_bucket, true) : false
  aws_bucket_name_raw     = var.mode == "aws" ? try(var.aws.bucket_name, null) : null
  aws_bucket_name_input   = var.mode == "aws" ? (local.aws_bucket_name_raw != null ? trimspace(local.aws_bucket_name_raw) : "") : ""
  aws_base_domain_trimmed = var.mode == "aws" ? trimspace(try(var.base_domain, "")) : ""
  aws_bucket_seed         = var.mode == "aws" ? (length(local.aws_base_domain_trimmed) > 0 ? local.aws_base_domain_trimmed : "btp") : ""
  aws_should_generate_bucket = (
    var.mode == "aws" &&
    local.aws_manage_bucket &&
    length(local.aws_bucket_name_input) == 0
  )
}

resource "random_id" "aws_bucket_suffix" {
  count       = local.aws_should_generate_bucket ? 1 : 0
  byte_length = 4

  keepers = {
    seed = local.aws_bucket_seed
  }
}

locals {
  aws_bucket_suffix_generated = local.aws_should_generate_bucket ? substr(try(random_id.aws_bucket_suffix[0].hex, md5(local.aws_bucket_seed)), 0, 10) : ""
  aws_bucket_name_effective = var.mode == "aws" ? (
    length(local.aws_bucket_name_input) > 0 ? local.aws_bucket_name_input :
    (local.aws_should_generate_bucket ? format("btp-%s-artifacts", local.aws_bucket_suffix_generated) : null)
  ) : null
  aws_identity_base = var.mode == "aws" ? (
    local.aws_bucket_name_effective != null ?
    replace(local.aws_bucket_name_effective, ".", "-") :
    "btp-artifacts"
  ) : null
  aws_identity_key         = var.mode == "aws" ? "default" : null
  aws_identity_user_name   = local.aws_identity_base != null ? "${local.aws_identity_base}-user" : "btp-artifacts-user"
  aws_identity_policy_name = local.aws_identity_base != null ? "${local.aws_identity_base}-policy" : "btp-artifacts-policy"
}

# S3 bucket for object storage
resource "aws_s3_bucket" "bucket" {
  count  = var.mode == "aws" && local.aws_manage_bucket ? 1 : 0
  bucket = local.aws_bucket_name_effective

  tags = {
    Name        = local.aws_bucket_name_effective
    ManagedBy   = "terraform"
    Application = "btp-object-storage"
  }

  force_destroy = try(var.aws.force_destroy, true)
}

# Enable versioning if configured
resource "aws_s3_bucket_versioning" "bucket" {
  count  = var.mode == "aws" && local.aws_manage_bucket ? 1 : 0
  bucket = aws_s3_bucket.bucket[0].id

  versioning_configuration {
    status = var.aws.versioning_enabled ? "Enabled" : "Suspended"
  }
}

# Enable server-side encryption by default
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  count  = var.mode == "aws" && local.aws_manage_bucket ? 1 : 0
  bucket = aws_s3_bucket.bucket[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.aws.kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.aws.kms_key_id
    }
    bucket_key_enabled = var.aws.kms_key_id != null ? true : false
  }
}

# Block public access by default (security best practice)
resource "aws_s3_bucket_public_access_block" "bucket" {
  count  = var.mode == "aws" && local.aws_manage_bucket && var.aws.block_public_access ? 1 : 0
  bucket = aws_s3_bucket.bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable lifecycle rules if configured
resource "aws_s3_bucket_lifecycle_configuration" "bucket" {
  count  = var.mode == "aws" && local.aws_manage_bucket && var.aws.lifecycle_rules != null ? 1 : 0
  bucket = aws_s3_bucket.bucket[0].id

  dynamic "rule" {
    for_each = var.aws.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      dynamic "transition" {
        for_each = rule.value.transitions != null ? rule.value.transitions : []
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration_days != null ? [1] : []
        content {
          days = rule.value.expiration_days
        }
      }
    }
  }
}

# Create an IAM user for programmatic access if no access keys provided
resource "aws_iam_user" "s3_user" {
  for_each = var.mode == "aws" && var.aws.create_iam_user ? { (local.aws_identity_key) = true } : {}

  name = local.aws_identity_user_name

  tags = {
    Name        = local.aws_identity_user_name
    ManagedBy   = "terraform"
    Application = "btp-object-storage"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# IAM policy for bucket access
resource "aws_iam_user_policy" "s3_user_policy" {
  for_each = aws_iam_user.s3_user

  name = local.aws_identity_policy_name
  user = aws_iam_user.s3_user[each.key].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = local.aws_bucket_arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${local.aws_bucket_arn}/*"
      }
    ]
  })
}

# Generate access keys for the IAM user
resource "aws_iam_access_key" "s3_user" {
  for_each = aws_iam_user.s3_user

  user = aws_iam_user.s3_user[each.key].name
}

data "aws_s3_bucket" "existing" {
  count  = var.mode == "aws" && !local.aws_manage_bucket ? 1 : 0
  bucket = local.aws_bucket_name_effective
}

locals {
  aws_bucket_id = var.mode == "aws" ? (
    local.aws_manage_bucket ? aws_s3_bucket.bucket[0].id : data.aws_s3_bucket.existing[0].id
  ) : null

  aws_bucket_arn = var.mode == "aws" ? (
    local.aws_manage_bucket ? aws_s3_bucket.bucket[0].arn : data.aws_s3_bucket.existing[0].arn
  ) : null

  aws_endpoint = var.mode == "aws" ? "https://s3.${var.aws.region}.amazonaws.com" : null
  aws_bucket   = var.mode == "aws" ? local.aws_bucket_id : null
  aws_access_key = var.mode == "aws" ? (
    var.aws.create_iam_user ?
    try(aws_iam_access_key.s3_user[local.aws_identity_key].id, null) :
    coalesce(var.aws.access_key, try(var.secrets.access_key, null))
  ) : null

  aws_secret_key = var.mode == "aws" ? (
    var.aws.create_iam_user ?
    try(aws_iam_access_key.s3_user[local.aws_identity_key].secret, null) :
    coalesce(var.aws.secret_key, try(var.secrets.secret_key, null))
  ) : null
  aws_region         = var.mode == "aws" ? var.aws.region : null
  aws_use_path_style = var.mode == "aws" ? false : null
}
