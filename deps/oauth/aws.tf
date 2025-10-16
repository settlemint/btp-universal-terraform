# AWS mode: AWS Cognito User Pool

# Create Cognito User Pool if not using an existing one
resource "aws_cognito_user_pool" "pool" {
  count = var.mode == "aws" && var.aws.user_pool_id == null ? 1 : 0
  name  = var.aws.user_pool_name

  # Password policy
  password_policy {
    minimum_length                   = var.aws.password_policy.minimum_length
    require_lowercase                = var.aws.password_policy.require_lowercase
    require_uppercase                = var.aws.password_policy.require_uppercase
    require_numbers                  = var.aws.password_policy.require_numbers
    require_symbols                  = var.aws.password_policy.require_symbols
    temporary_password_validity_days = var.aws.password_policy.temporary_password_validity_days
  }

  # Auto-verified attributes
  auto_verified_attributes = var.aws.auto_verified_attributes

  # Email configuration
  email_configuration {
    email_sending_account = var.aws.email_configuration.email_sending_account
    source_arn            = var.aws.email_configuration.source_arn
    from_email_address    = var.aws.email_configuration.from_email_address
  }

  # User attribute schema
  schema {
    attribute_data_type      = "String"
    name                     = "email"
    required                 = true
    mutable                  = true
    developer_only_attribute = false

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  # Account recovery setting
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # MFA configuration
  mfa_configuration = var.aws.mfa_configuration

  tags = {
    Name        = var.aws.user_pool_name
    ManagedBy   = "terraform"
    Application = "btp-oauth"
  }

  # Ensure pool is only destroyed after domain is deleted
  lifecycle {
    create_before_destroy = false
  }
}

# Create Cognito User Pool Client
resource "aws_cognito_user_pool_client" "client" {
  count        = var.mode == "aws" && var.aws.client_id == null ? 1 : 0
  name         = var.aws.client_name
  user_pool_id = var.aws.user_pool_id != null ? var.aws.user_pool_id : aws_cognito_user_pool.pool[0].id

  # OAuth settings
  generate_secret                      = true
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  callback_urls                        = var.aws.callback_urls
  logout_urls                          = var.aws.logout_urls
  supported_identity_providers         = ["COGNITO"]

  # Token validity
  access_token_validity  = var.aws.token_validity.access_token_validity
  id_token_validity      = var.aws.token_validity.id_token_validity
  refresh_token_validity = var.aws.token_validity.refresh_token_validity

  token_validity_units {
    access_token  = var.aws.token_validity.access_token_validity_units
    id_token      = var.aws.token_validity.id_token_validity_units
    refresh_token = var.aws.token_validity.refresh_token_validity_units
  }

  # Prevent destroy on updates
  prevent_user_existence_errors = "ENABLED"

  # Read/write attributes
  read_attributes  = var.aws.read_attributes
  write_attributes = var.aws.write_attributes
}

# Data source to get user pool information if using existing pool
data "aws_cognito_user_pool" "existing" {
  count        = var.mode == "aws" && var.aws.user_pool_id != null ? 1 : 0
  user_pool_id = var.aws.user_pool_id
}

locals {
  base_domain_slug = var.mode == "aws" ? substr(replace(replace(lower(var.base_domain), ".", "-"), "_", "-"), 0, 52) : null

  sanitized_domain_slug = var.mode == "aws" && local.base_domain_slug != null ? join(
    "-",
    compact(
      split(
        "-",
        replace(
          replace(
            replace(
              replace(local.base_domain_slug, "-aws-", "-"),
              "aws-",
              ""
            ),
            "-aws",
            "-"
          ),
          "aws",
          ""
        )
      )
    )
  ) : null

  fallback_domain_prefix = var.mode == "aws" ? (
    length(try(local.sanitized_domain_slug, "")) >= 3 ?
    local.sanitized_domain_slug :
    format("btp-%s", substr(md5(var.base_domain), 0, 10))
  ) : null

  provided_domain_prefix = var.mode == "aws" && try(var.aws.domain_prefix, null) != null ? trimspace(var.aws.domain_prefix) : ""

  derived_domain_prefix = var.mode == "aws" ? (
    length(local.provided_domain_prefix) > 0 ?
    local.provided_domain_prefix :
    local.fallback_domain_prefix
  ) : null
}

resource "aws_cognito_user_pool_domain" "pool_domain" {
  count        = var.mode == "aws" && var.aws.user_pool_id == null && local.derived_domain_prefix != null ? 1 : 0
  domain       = local.derived_domain_prefix
  user_pool_id = aws_cognito_user_pool.pool[0].id

  lifecycle {
    create_before_destroy = false
  }
}

locals {
  # Determine which user pool to use
  user_pool_id = var.mode == "aws" ? (
    var.aws.user_pool_id != null ? var.aws.user_pool_id : aws_cognito_user_pool.pool[0].id
  ) : null
  aws_domain_host   = var.mode == "aws" && local.derived_domain_prefix != null ? "${local.derived_domain_prefix}.auth.${var.aws.region}.amazoncognito.com" : null
  aws_issuer        = var.mode == "aws" ? "https://cognito-idp.${var.aws.region}.amazonaws.com/${local.user_pool_id}" : null
  aws_admin_url     = var.mode == "aws" ? "https://${var.aws.region}.console.aws.amazon.com/cognito/v2/idp/user-pools/${local.user_pool_id}" : null
  aws_client_id     = var.mode == "aws" ? (var.aws.client_id != null ? var.aws.client_id : aws_cognito_user_pool_client.client[0].id) : null
  aws_client_secret = var.mode == "aws" ? (var.aws.client_id != null ? var.aws.client_secret : aws_cognito_user_pool_client.client[0].client_secret) : null
  aws_scopes        = var.mode == "aws" ? ["openid", "email", "profile"] : null
  aws_callback_urls = var.mode == "aws" ? var.aws.callback_urls : null
}
