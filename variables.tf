variable "platform" {
  description = "Target platform: aws | azure | gcp | generic. OrbStack uses generic."
  type        = string
  default     = "generic"
}

variable "base_domain" {
  description = "Base domain for local ingress. Use 127.0.0.1.nip.io for OrbStack."
  type        = string
  default     = "127.0.0.1.nip.io"
}

variable "cluster" {
  description = "Cluster connection configuration. For OrbStack/local, set create=false and use current kube context or provide kubeconfig_path."
  type = object({
    create          = optional(bool, false)
    name            = optional(string)
    version         = optional(string)
    region          = optional(string)
    node_groups     = optional(map(object({ instance_type = string, desired = number })), {})
    kubeconfig_path = optional(string)
  })
  default = {
    create          = false
    kubeconfig_path = null
  }
}

variable "namespaces" {
  description = "Namespaces per dependency (override to split)."
  type = object({
    ingress_tls    = optional(string, "btp-deps")
    postgres       = optional(string, "btp-deps")
    redis          = optional(string, "btp-deps")
    object_storage = optional(string, "btp-deps")
    metrics_logs   = optional(string, "btp-deps")
    oauth          = optional(string, "btp-deps")
    secrets        = optional(string, "btp-deps")
  })
  default = {}
}

# VPC configuration for AWS deployments
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

# Dependency configs (k8s mode for v1)
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

variable "ingress_tls" {
  type = object({
    mode = optional(string, "k8s")
    k8s = optional(object({
      namespace                  = optional(string)
      nginx_chart_version        = optional(string)
      cert_manager_chart_version = optional(string)
      release_name_nginx         = optional(string)
      release_name_cert_manager  = optional(string)
      issuer_name                = optional(string)
      values_nginx               = optional(map(any), {})
      values_cert_manager        = optional(map(any), {})
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

# Convenience env-mappable var to override Vault dev token without nested objects
variable "secrets_dev_token" {
  description = "Vault dev root token to expose via outputs when dev_mode is true (overrides secrets.k8s.dev_token if set)."
  type        = string
  default     = null
}

# SettleMint Platform (Helm) deployment
variable "btp" {
  description = "Configure deployment of the SettleMint Platform Helm chart (disabled by default)."
  type = object({
    enabled       = optional(bool, false)
    namespace     = optional(string, "settlemint")
    release_name  = optional(string, "settlemint-platform")
    chart         = optional(string, "oci://registry.settlemint.com/settlemint-platform/SettleMint")
    chart_version = optional(string)
    values        = optional(map(any), {})
    values_file   = optional(string)
  })
  default = {}
}

# Convenience env-mappable overrides for dependency credentials
variable "redis_password" {
  description = "Override Redis password (dev/prod). If unset, a random password is generated."
  type        = string
  default     = null
}

variable "object_storage_access_key" {
  description = "Override MinIO access key (rootUser). If unset, defaults to 'minio'."
  type        = string
  default     = null
}

variable "object_storage_secret_key" {
  description = "Override MinIO secret key (rootPassword). If unset, a random password is generated."
  type        = string
  default     = null
}

variable "grafana_admin_password" {
  description = "Override Grafana admin password. If unset, a random password is generated."
  type        = string
  default     = null
}

variable "oauth_admin_password" {
  description = "Override Keycloak admin password. If unset, a random password is generated."
  type        = string
  default     = null
}

# License inputs for the platform chart (injected into btp.values.license)
variable "license_username" {
  type    = string
  default = null
}

variable "license_password" {
  type    = string
  default = null
}

variable "license_signature" {
  type    = string
  default = null
}

variable "license_email" {
  type    = string
  default = null
}

variable "license_expiration_date" {
  type    = string
  default = null
}

# Platform security secrets
variable "jwt_signing_key" {
  description = "JWT signing key for authentication (optional). If not provided, a random key will be generated."
  type        = string
  default     = null
  sensitive   = true
}

variable "ipfs_cluster_secret" {
  description = "IPFS cluster secret for distributed storage (optional). If not provided, a random secret will be generated."
  type        = string
  default     = null
  sensitive   = true
}

variable "state_encryption_key" {
  description = "Encryption key for deployment engine state (optional). If not provided, a random key will be generated."
  type        = string
  default     = null
  sensitive   = true
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
