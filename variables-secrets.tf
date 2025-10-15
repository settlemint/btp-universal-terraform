# Credentials and secrets configuration variables
# All secrets must be provided via TF_VAR_* environment variables or 1Password CLI injection

# Dependency credentials (REQUIRED)
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

# License inputs for the platform chart (injected into btp.values.license)
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

# Platform security secrets (REQUIRED)
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

# Google OAuth (temporary - for AWS + Google auth setup)
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
