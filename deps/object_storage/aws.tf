# AWS mode: Deploy S3 bucket
# TODO: Implement AWS S3 bucket with IAM policies

# Placeholder for AWS S3 implementation
# resource "aws_s3_bucket" "bucket" {
#   count  = var.mode == "aws" ? 1 : 0
#   bucket = var.aws.bucket_name
#   tags = {
#     Name = "btp-object-storage"
#   }
# }
#
# resource "aws_s3_bucket_versioning" "bucket" {
#   count  = var.mode == "aws" ? 1 : 0
#   bucket = aws_s3_bucket.bucket[0].id
#   versioning_configuration {
#     status = var.aws.versioning_enabled ? "Enabled" : "Disabled"
#   }
# }

locals {
  aws_endpoint       = var.mode == "aws" ? "https://s3.${var.aws.region}.amazonaws.com" : null
  aws_bucket         = var.mode == "aws" ? var.aws.bucket_name : null
  aws_access_key     = var.mode == "aws" ? var.aws.access_key : null
  aws_secret_key     = var.mode == "aws" ? var.aws.secret_key : null
  aws_region         = var.mode == "aws" ? var.aws.region : null
  aws_use_path_style = var.mode == "aws" ? false : null
}
