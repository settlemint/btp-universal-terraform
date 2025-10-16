# Root module input variables

## Core and infrastructure configuration

variable "platform" {
  description = "Target platform: aws | azure | gcp | generic. OrbStack uses generic."
  type        = string
  default     = "generic"

  validation {
    condition     = contains(["aws", "azure", "gcp", "generic"], var.platform)
    error_message = "Platform must be one of: aws, azure, gcp, generic"
  }
}

variable "base_domain" {
  description = "Base domain for local ingress. Use 127.0.0.1.nip.io for OrbStack."
  type        = string
  default     = "127.0.0.1.nip.io"

  validation {
    condition     = can(regex("^[a-z0-9.-]+$", var.base_domain))
    error_message = "Base domain must be a valid domain name (lowercase alphanumeric, dots, and dashes only)"
  }
}

variable "namespaces" {
  description = "Namespaces per dependency (override to split)."
  type = object({
    ingress_tls    = optional(string)
    postgres       = optional(string)
    redis          = optional(string)
    object_storage = optional(string)
    metrics_logs   = optional(string)
    oauth          = optional(string)
    secrets        = optional(string)
  })
  default = {
    ingress_tls    = "btp-deps"
    postgres       = "btp-deps"
    redis          = "btp-deps"
    object_storage = "btp-deps"
    metrics_logs   = "btp-deps"
    oauth          = "btp-deps"
    secrets        = "btp-deps"
  }
}

variable "vpc" {
  description = "VPC configuration for AWS platform"
  type = object({
    aws = optional(object({
      create_vpc                             = optional(bool, true)
      vpc_name                               = optional(string, "btp-vpc")
      vpc_cidr                               = optional(string, "10.0.0.0/16")
      region                                 = optional(string, "us-east-1")
      availability_zones                     = optional(list(string), ["us-east-1a", "us-east-1b", "us-east-1c"])
      enable_nat_gateway                     = optional(bool, true)
      single_nat_gateway                     = optional(bool, true)
      enable_s3_endpoint                     = optional(bool, true)
      additional_security_group_ids          = optional(list(string), [])
      existing_vpc_id                        = optional(string)
      existing_private_subnet_ids            = optional(list(string), [])
      existing_public_subnet_ids             = optional(list(string), [])
      existing_rds_security_group_id         = optional(string)
      existing_elasticache_security_group_id = optional(string)
    }), {})
  })
  default = {}
}

variable "k8s_cluster" {
  description = "Managed Kubernetes cluster configuration (EKS, AKS, GKE) or BYO cluster"
  type = object({
    mode  = optional(string, "disabled") # aws | azure | gcp | byo | disabled
    aws   = optional(any, {})            # AWS EKS configuration (see deps/k8s_cluster/variables.tf)
    azure = optional(any, {})            # Azure AKS configuration
    gcp   = optional(any, {})            # GCP GKE configuration
    byo   = optional(any, null)          # Bring Your Own cluster (kubeconfig)
  })
  default = {}
}

## Dependency configuration

variable "postgres" {
  type = object({
    mode = optional(string, "k8s")
    k8s = optional(object({
      namespace                        = optional(string)
      operator_chart_version           = optional(string)
      postgresql_version               = optional(string)
      release_name                     = optional(string)
      values                           = optional(map(any), {})
      database                         = optional(string)
      credentials_secret_name_override = optional(string)
      enable_ssl                       = optional(bool)
      pg_hba_rules                     = optional(list(string))
    }), {})
    aws = optional(object({
      identifier          = optional(string)
      engine_version      = optional(string)
      instance_class      = optional(string)
      allocated_storage   = optional(number)
      database            = optional(string)
      username            = optional(string)
      password            = optional(string)
      security_group_ids  = optional(list(string))
      subnet_group_name   = optional(string)
      skip_final_snapshot = optional(bool)
    }), {})
    azure = optional(object({
      server_name         = optional(string)
      resource_group_name = optional(string)
      location            = optional(string)
      version             = optional(string)
      sku_name            = optional(string)
      storage_mb          = optional(number)
      database            = optional(string)
      admin_username      = optional(string)
      admin_password      = optional(string)
    }), {})
    gcp = optional(object({
      instance_name    = optional(string)
      database_version = optional(string)
      region           = optional(string)
      tier             = optional(string)
      database         = optional(string)
      username         = optional(string)
      password         = optional(string)
    }), {})
    byo = optional(object({
      host     = string
      port     = number
      username = string
      password = string
      database = string
    }))
  })
  default = {}
}

variable "redis" {
  type = object({
    mode = optional(string, "k8s")
    k8s = optional(object({
      namespace     = optional(string)
      chart_version = optional(string)
      release_name  = optional(string)
      values        = optional(map(any), {})
      password      = optional(string)
    }), {})
    aws = optional(object({
      cluster_id                 = optional(string)
      engine_version             = optional(string)
      node_type                  = optional(string)
      parameter_group_name       = optional(string)
      security_group_ids         = optional(list(string))
      subnet_group_name          = optional(string)
      auth_token                 = optional(string)
      transit_encryption_enabled = optional(bool)
    }), {})
    azure = optional(object({
      cache_name          = optional(string)
      location            = optional(string)
      resource_group_name = optional(string)
      capacity            = optional(number)
      family              = optional(string)
      sku_name            = optional(string)
      ssl_enabled         = optional(bool)
      primary_access_key  = optional(string)
    }), {})
    gcp = optional(object({
      instance_name           = optional(string)
      tier                    = optional(string)
      memory_size_gb          = optional(number)
      region                  = optional(string)
      redis_version           = optional(string)
      auth_string             = optional(string)
      transit_encryption_mode = optional(string)
    }), {})
    byo = optional(object({
      host        = string
      port        = number
      password    = optional(string)
      scheme      = optional(string)
      tls_enabled = optional(bool)
    }))
  })
  default = {}
}

variable "object_storage" {
  type = object({
    mode = optional(string, "k8s")
    k8s = optional(object({
      namespace      = optional(string)
      chart_version  = optional(string)
      release_name   = optional(string)
      values         = optional(map(any), {})
      default_bucket = optional(string)
      access_key     = optional(string)
      secret_key     = optional(string)
    }), {})
    aws = optional(object({
      bucket_name        = optional(string)
      region             = optional(string)
      access_key         = optional(string)
      secret_key         = optional(string)
      versioning_enabled = optional(bool)
    }), {})
    azure = optional(object({
      storage_account_name = optional(string)
      container_name       = optional(string)
      resource_group_name  = optional(string)
      location             = optional(string)
      account_tier         = optional(string)
      replication_type     = optional(string)
      access_key           = optional(string)
    }), {})
    gcp = optional(object({
      bucket_name   = optional(string)
      location      = optional(string)
      storage_class = optional(string)
      access_key    = optional(string)
      secret_key    = optional(string)
    }), {})
    byo = optional(object({
      endpoint       = string
      bucket         = string
      access_key     = string
      secret_key     = string
      region         = optional(string)
      use_path_style = optional(bool)
    }))
  })
  default = {}
}

variable "dns" {
  type = object({
    mode                    = optional(string, "byo")
    domain                  = optional(string)
    enable_wildcard         = optional(bool)
    include_wildcard_in_tls = optional(bool)
    cert_manager_issuer     = optional(string)
    tls_secret_name         = optional(string)
    ssl_redirect            = optional(bool)
    annotations             = optional(map(string), {})
    aws = optional(object({
      zone_id           = optional(string)
      zone_name         = optional(string)
      main_record_type  = optional(string)
      main_record_value = optional(string)
      main_ttl          = optional(number)
      alias = optional(object({
        name                   = string
        zone_id                = string
        evaluate_target_health = optional(bool)
        type                   = optional(string)
      }))
      wildcard_record_type  = optional(string)
      wildcard_record_value = optional(string)
      wildcard_ttl          = optional(number)
      wildcard_alias = optional(object({
        name                   = string
        zone_id                = string
        evaluate_target_health = optional(bool)
        type                   = optional(string)
      }))
    }), null)
    azure = optional(object({
      resource_group_name   = string
      zone_name             = string
      main_record_type      = optional(string)
      main_record_value     = string
      main_ttl              = optional(number)
      wildcard_record_type  = optional(string)
      wildcard_record_value = optional(string)
      wildcard_ttl          = optional(number)
    }), null)
    gcp = optional(object({
      managed_zone          = string
      project               = optional(string)
      main_record_type      = optional(string)
      main_record_value     = string
      main_ttl              = optional(number)
      wildcard_record_type  = optional(string)
      wildcard_record_value = optional(string)
      wildcard_ttl          = optional(number)
    }), null)
    cf = optional(object({
      api_token             = optional(string)
      zone_id               = optional(string)
      zone_name             = optional(string)
      proxied               = optional(bool)
      main_record_type      = optional(string)
      main_record_value     = string
      main_ttl              = optional(number)
      wildcard_record_type  = optional(string)
      wildcard_record_value = optional(string)
      wildcard_ttl          = optional(number)
    }), null)
    byo = optional(object({
      ingress_annotations = optional(map(string), {})
      tls_secret_name     = optional(string)
      tls_hosts           = optional(list(string))
      ssl_redirect        = optional(bool)
    }), {})
  })
  default = {}

  validation {
    condition     = !(try(var.dns.mode, "byo") == "cf" && try(var.dns.cf.api_token, null) == null)
    error_message = "When dns.mode is \"cf\", provide dns.cf.api_token (CLOUDFLARE_API_TOKEN)."
  }

  validation {
    condition     = !(try(var.dns.mode, "byo") == "aws" && try(var.dns.aws, null) == null)
    error_message = "When dns.mode is \"aws\", provide dns.aws configuration."
  }

  validation {
    condition = !(
      try(var.dns.mode, "byo") == "aws" &&
      try(var.dns.aws, null) != null &&
      try(var.dns.aws.zone_id, null) == null &&
      try(var.dns.aws.zone_name, null) == null
    )
    error_message = "When dns.mode is \"aws\", set dns.aws.zone_id or dns.aws.zone_name."
  }
}

variable "ingress_tls" {
  type = object({
    mode = optional(string, "k8s")
    k8s = optional(object({
      namespace                       = optional(string)
      nginx_chart_version             = optional(string)
      cert_manager_chart_version      = optional(string)
      release_name_nginx              = optional(string)
      release_name_cert_manager       = optional(string)
      issuer_name                     = optional(string)
      values_nginx                    = optional(map(any), {})
      values_cert_manager             = optional(map(any), {})
      route53_credentials_secret_name = optional(string)
      acme_email                      = optional(string)
      acme_environment                = optional(string, "staging")
    }), {})
  })
  default = {}
}

variable "metrics_logs" {
  type = object({
    mode = optional(string, "k8s")
    k8s = optional(object({
      namespace                = optional(string)
      kp_stack_chart_version   = optional(string)
      loki_stack_chart_version = optional(string)
      release_name_kps         = optional(string)
      release_name_loki        = optional(string)
      values                   = optional(map(any), {})
    }), {})
  })
  default = {}
}

variable "oauth" {
  type = object({
    mode = optional(string, "disabled")
    k8s = optional(object({
      namespace       = optional(string)
      chart_version   = optional(string)
      release_name    = optional(string)
      values          = optional(map(any), {})
      ingress_enabled = optional(bool)
      admin_password  = optional(string)
    }), {})
    aws = optional(object({
      region         = optional(string)
      user_pool_id   = optional(string)
      user_pool_name = optional(string)
      client_id      = optional(string)
      client_name    = optional(string)
      client_secret  = optional(string)
      callback_urls  = optional(list(string))
    }), {})
    azure = optional(object({
      tenant_id           = optional(string)
      tenant_name         = optional(string)
      resource_group_name = optional(string)
      location            = optional(string)
      domain_name         = optional(string)
      sku_name            = optional(string)
      client_id           = optional(string)
      client_secret       = optional(string)
      callback_urls       = optional(list(string))
    }), {})
    gcp = optional(object({
      project_id    = optional(string)
      client_id     = optional(string)
      client_secret = optional(string)
      callback_urls = optional(list(string))
    }), {})
    byo = optional(object({
      issuer        = string
      admin_url     = optional(string)
      client_id     = optional(string)
      client_secret = optional(string)
      scopes        = optional(list(string))
      callback_urls = optional(list(string))
    }))
  })
  default = {}
}

variable "secrets" {
  type = object({
    mode = optional(string, "k8s")
    k8s = optional(object({
      namespace     = optional(string)
      chart_version = optional(string)
      release_name  = optional(string)
      values        = optional(map(any), {})
      dev_mode      = optional(bool)
      dev_token     = optional(string)
    }), {})
    aws = optional(object({
      region = optional(string)
    }), {})
    azure = optional(object({
      key_vault_name      = optional(string)
      location            = optional(string)
      resource_group_name = optional(string)
      tenant_id           = optional(string)
      sku_name            = optional(string)
    }), {})
    gcp = optional(object({
      project_id = optional(string)
    }), {})
    byo = optional(object({
      vault_addr = string
      token      = optional(string)
      kv_mount   = optional(string)
      paths      = optional(list(string))
    }))
  })
  default = {}
}

variable "secrets_dev_token" {
  description = "Vault dev root token to expose via outputs when dev_mode is true (overrides secrets.k8s.dev_token if set)."
  type        = string
  default     = null
  sensitive   = true
}

## Credentials and secret inputs

variable "postgres_password" {
  description = "PostgreSQL password. Must be provided via TF_VAR_postgres_password. Must be 8-128 characters and cannot contain /, ', \", @, or space."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.postgres_password) >= 8 && length(var.postgres_password) <= 128
    error_message = "PostgreSQL password must be between 8 and 128 characters."
  }
}

variable "redis_password" {
  description = "Redis password (dev/prod). Must be provided via TF_VAR_redis_password."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.redis_password) >= 16
    error_message = "Redis password must be at least 16 characters for security."
  }
}

variable "object_storage_access_key" {
  description = "MinIO/S3 access key (rootUser). Must be provided via TF_VAR_object_storage_access_key."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.object_storage_access_key) >= 3
    error_message = "Object storage access key must be at least 3 characters."
  }
}

variable "object_storage_secret_key" {
  description = "MinIO/S3 secret key (rootPassword). Must be provided via TF_VAR_object_storage_secret_key."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.object_storage_secret_key) >= 20
    error_message = "Object storage secret key must be at least 20 characters for security."
  }
}

variable "grafana_admin_password" {
  description = "Grafana admin password. Must be provided via TF_VAR_grafana_admin_password."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.grafana_admin_password) >= 12
    error_message = "Grafana admin password must be at least 12 characters for security."
  }
}

variable "oauth_admin_password" {
  description = "Keycloak admin password. Must be provided via TF_VAR_oauth_admin_password."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.oauth_admin_password) >= 16
    error_message = "OAuth admin password must be at least 16 characters for security."
  }
}

variable "license_username" {
  type      = string
  default   = null
  sensitive = true
}

variable "license_password" {
  type      = string
  default   = null
  sensitive = true
}

variable "license_signature" {
  type      = string
  default   = null
  sensitive = true
}

variable "license_email" {
  type    = string
  default = null
}

variable "license_expiration_date" {
  type    = string
  default = null
}

variable "jwt_signing_key" {
  description = "JWT signing key for authentication. Must be provided via TF_VAR_jwt_signing_key. Minimum 32 characters."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.jwt_signing_key) >= 32
    error_message = "JWT signing key must be at least 32 characters for security."
  }
}

variable "ipfs_cluster_secret" {
  description = "IPFS cluster secret for distributed storage. Must be a 64-character hex string. Must be provided via TF_VAR_ipfs_cluster_secret."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.ipfs_cluster_secret) == 64 && can(regex("^[0-9a-fA-F]{64}$", var.ipfs_cluster_secret))
    error_message = "IPFS cluster secret must be exactly 64 hexadecimal characters."
  }
}

variable "state_encryption_key" {
  description = "Encryption key for deployment engine state (base64 encoded). Must be provided via TF_VAR_state_encryption_key. Minimum 32 characters."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.state_encryption_key) >= 32
    error_message = "State encryption key must be at least 32 characters for security."
  }
}

variable "aws_access_key_id" {
  description = "AWS access key ID for cloud storage (optional)"
  type        = string
  default     = null
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS secret access key for cloud storage (optional)"
  type        = string
  default     = null
  sensitive   = true
}

variable "google_oauth_client_id" {
  description = "Google OAuth client ID (optional - for temporary Google auth on AWS)"
  type        = string
  default     = null
  sensitive   = false
}

variable "google_oauth_client_secret" {
  description = "Google OAuth client secret (optional - for temporary Google auth on AWS)"
  type        = string
  default     = null
  sensitive   = true
}

## Platform deployment configuration

variable "btp" {
  description = "Configure deployment of the SettleMint Platform Helm chart (disabled by default)."
  type = object({
    enabled              = optional(bool, false)
    namespace            = optional(string, "settlemint")
    deployment_namespace = optional(string, "deployments")
    release_name         = optional(string, "settlemint-platform")
    chart                = optional(string, "oci://registry.example.com/settlemint-platform/SettleMint")
    chart_version        = optional(string)
    values               = optional(map(any), {})
    values_file          = optional(string)
  })
  default = {}
}
