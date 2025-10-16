variable "chart" {
  description = "Full chart reference (supports OCI). Note: OCI repository paths must be lowercase."
  type        = string
  default     = "oci://harbor.example.com/settlemint/settlemint"
}

variable "chart_version" {
  type    = string
  default = ""
}

variable "namespace" {
  type    = string
  default = "settlemint"
}

variable "deployment_namespace" {
  description = "Kubernetes namespace for workload deployments referenced in auto-generated values"
  type        = string
  default     = "deployments"
}

variable "values" {
  type    = map(any)
  default = {}
}

variable "values_file" {
  description = "Path to YAML file containing Helm values"
  type        = string
  default     = null
}

variable "release_name" {
  description = "Helm release name for the platform"
  type        = string
  default     = "settlemint-platform"
}

variable "create_namespace" {
  description = "Create the target namespace if it doesn't exist"
  type        = bool
  default     = true
}

variable "base_domain" {
  description = "Base domain to use for ingress host defaults, if needed"
  type        = string
  default     = null
}

# Dependency inputs (normalized)
variable "postgres" { type = any }
variable "redis" { type = any }
variable "object_storage" { type = any }
variable "oauth" { type = any }
variable "secrets" { type = any }
variable "ingress_tls" { type = any }
variable "metrics_logs" { type = any }
variable "dns" {
  description = "Normalized DNS configuration and ingress hints"
  type = object({
    hostname            = string
    wildcard_hostname   = optional(string)
    tls_secret_name     = string
    tls_hosts           = list(string)
    ingress_annotations = optional(map(string))
    ssl_redirect        = optional(bool)
  })
  default  = null
  nullable = true
}

# Optional license fields; if provided, injected into chart values under .license
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
  description = "ISO8601 date string for license expiration if required by chart values"
  type        = string
  default     = null
}

# Platform security secrets
variable "jwt_signing_key" {
  description = "JWT signing key for authentication"
  type        = string
  default     = null
  sensitive   = true
}

variable "ipfs_cluster_secret" {
  description = "IPFS cluster secret for distributed storage"
  type        = string
  default     = null
  sensitive   = true
}

variable "state_encryption_key" {
  description = "Encryption key for deployment engine state"
  type        = string
  default     = null
  sensitive   = true
}

variable "aws_access_key_id" {
  description = "AWS access key ID for cloud storage"
  type        = string
  default     = null
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS secret access key for cloud storage"
  type        = string
  default     = null
  sensitive   = true
}

variable "google_oauth_client_id" {
  description = "Google OAuth client ID"
  type        = string
  default     = null
  sensitive   = false
}

variable "google_oauth_client_secret" {
  description = "Google OAuth client secret"
  type        = string
  default     = null
  sensitive   = true
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  default     = null
  sensitive   = true
}
