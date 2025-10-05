# AWS mode: Deploy S3 bucket

# S3 bucket for object storage
resource "aws_s3_bucket" "bucket" {
  count  = var.mode == "aws" ? 1 : 0
  bucket = var.aws.bucket_name

  tags = {
    Name        = var.aws.bucket_name
    ManagedBy   = "terraform"
    Application = "btp-object-storage"
  }
}

# Enable versioning if configured
resource "aws_s3_bucket_versioning" "bucket" {
  count  = var.mode == "aws" ? 1 : 0
  bucket = aws_s3_bucket.bucket[0].id

  versioning_configuration {
    status = var.aws.versioning_enabled ? "Enabled" : "Suspended"
  }
}

# Enable server-side encryption by default
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  count  = var.mode == "aws" ? 1 : 0
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
  count  = var.mode == "aws" && var.aws.block_public_access ? 1 : 0
  bucket = aws_s3_bucket.bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable lifecycle rules if configured
resource "aws_s3_bucket_lifecycle_configuration" "bucket" {
  count  = var.mode == "aws" && var.aws.lifecycle_rules != null ? 1 : 0
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
  count = var.mode == "aws" && var.aws.create_iam_user ? 1 : 0
  name  = "${var.aws.bucket_name}-user"

  tags = {
    Name        = "${var.aws.bucket_name}-user"
    ManagedBy   = "terraform"
    Application = "btp-object-storage"
  }
}

# IAM policy for bucket access
resource "aws_iam_user_policy" "s3_user_policy" {
  count = var.mode == "aws" && var.aws.create_iam_user ? 1 : 0
  name  = "${var.aws.bucket_name}-policy"
  user  = aws_iam_user.s3_user[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = aws_s3_bucket.bucket[0].arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.bucket[0].arn}/*"
      }
    ]
  })
}

# Generate access keys for the IAM user
resource "aws_iam_access_key" "s3_user" {
  count = var.mode == "aws" && var.aws.create_iam_user ? 1 : 0
  user  = aws_iam_user.s3_user[0].name
}

locals {
  aws_endpoint       = var.mode == "aws" ? "https://s3.${var.aws.region}.amazonaws.com" : null
  aws_bucket         = var.mode == "aws" ? aws_s3_bucket.bucket[0].id : null
  aws_access_key     = var.mode == "aws" ? (var.aws.create_iam_user ? aws_iam_access_key.s3_user[0].id : var.aws.access_key) : null
  aws_secret_key     = var.mode == "aws" ? (var.aws.create_iam_user ? aws_iam_access_key.s3_user[0].secret : var.aws.secret_key) : null
  aws_region         = var.mode == "aws" ? var.aws.region : null
  aws_use_path_style = var.mode == "aws" ? false : null
}
