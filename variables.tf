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
    }), {})
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
    }), {})
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
    }), {})
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
      namespace     = optional(string)
      chart_version = optional(string)
      release_name  = optional(string)
      values        = optional(map(any), {})
    }), {})
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
