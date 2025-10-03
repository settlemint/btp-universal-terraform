variable "mode" {
  type        = string
  description = "Deployment mode: k8s | aws | azure | gcp | byo"
  default     = "k8s"
  validation {
    condition     = contains(["k8s", "aws", "azure", "gcp", "byo"], var.mode)
    error_message = "Mode must be one of: k8s, aws, azure, gcp, byo"
  }
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace (used for k8s mode)"
  default     = "btp-deps"
}

variable "manage_namespace" {
  description = "Whether this module should create the namespace. Set false if namespaces are managed at root."
  type        = bool
  default     = false
}

# Kubernetes-specific variables
variable "k8s" {
  type = object({
    chart_version  = optional(string, "17.0.21")
    release_name   = optional(string, "minio")
    values         = optional(map(any), {})
    default_bucket = optional(string, "btp-artifacts")
    access_key     = optional(string)
    secret_key     = optional(string)
  })
  default     = {}
  description = "Kubernetes (MinIO Helm chart) configuration"
}

# AWS-specific variables
variable "aws" {
  type = object({
    bucket_name        = optional(string, "btp-artifacts")
    region             = optional(string, "us-east-1")
    access_key         = optional(string)
    secret_key         = optional(string)
    versioning_enabled = optional(bool, false)
  })
  default     = {}
  description = "AWS S3 configuration"
}

# Azure-specific variables
variable "azure" {
  type = object({
    storage_account_name = optional(string, "btpstorage")
    container_name       = optional(string, "btp-artifacts")
    resource_group_name  = optional(string)
    location             = optional(string)
    account_tier         = optional(string, "Standard")
    replication_type     = optional(string, "LRS")
    access_key           = optional(string)
  })
  default     = {}
  description = "Azure Blob Storage configuration"
}

# GCP-specific variables
variable "gcp" {
  type = object({
    bucket_name   = optional(string, "btp-artifacts")
    location      = optional(string, "US")
    storage_class = optional(string, "STANDARD")
    access_key    = optional(string)
    secret_key    = optional(string)
  })
  default     = {}
  description = "GCP Cloud Storage configuration"
}

# BYO-specific variables
variable "byo" {
  type = object({
    endpoint       = string
    bucket         = string
    access_key     = string
    secret_key     = string
    region         = optional(string, "us-east-1")
    use_path_style = optional(bool, true)
  })
  default     = null
  description = "Bring-your-own object storage configuration (S3-compatible)"
}
