# AWS mode: AWS Cognito User Pool
# TODO: Implement AWS Cognito User Pool

# Placeholder for AWS Cognito implementation
# resource "aws_cognito_user_pool" "pool" {
#   count = var.mode == "aws" ? 1 : 0
#   name  = var.aws.user_pool_name
# }
#
# resource "aws_cognito_user_pool_client" "client" {
#   count        = var.mode == "aws" ? 1 : 0
#   name         = var.aws.client_name
#   user_pool_id = aws_cognito_user_pool.pool[0].id
# }

locals {
  aws_issuer        = var.mode == "aws" ? "https://cognito-idp.${var.aws.region}.amazonaws.com/${var.aws.user_pool_id}" : null
  aws_admin_url     = var.mode == "aws" ? "https://console.aws.amazon.com/cognito" : null
  aws_client_id     = var.mode == "aws" ? var.aws.client_id : null
  aws_client_secret = var.mode == "aws" ? var.aws.client_secret : null
  aws_scopes        = var.mode == "aws" ? ["openid", "email", "profile"] : null
  aws_callback_urls = var.mode == "aws" ? var.aws.callback_urls : null
}
