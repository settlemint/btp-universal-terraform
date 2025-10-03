# AWS mode: AWS Secrets Manager integration
# TODO: Implement AWS Secrets Manager integration (optional, mainly for config/credentials storage)

# Placeholder for AWS Secrets Manager
# For now, AWS Secrets Manager is typically used directly by apps via SDK/IAM
# This module could provide centralized secret paths/policies if needed

locals {
  aws_vault_addr = var.mode == "aws" ? null : null  # Not applicable
  aws_token      = var.mode == "aws" ? null : null  # IAM-based auth
  aws_kv_mount   = var.mode == "aws" ? null : null
  aws_paths      = var.mode == "aws" ? [] : null
}
