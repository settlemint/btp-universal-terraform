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
  default     = true
}

variable "base_domain" {
  type        = string
  description = "Base domain used to derive unique resource identifiers (e.g., bucket names)."
  default     = ""
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
    bucket_name         = optional(string)
    region              = optional(string, "us-east-1")
    access_key          = optional(string)
    secret_key          = optional(string)
    versioning_enabled  = optional(bool, false)
    kms_key_id          = optional(string)
    block_public_access = optional(bool, true)
    force_destroy       = optional(bool, true)
    create_iam_user     = optional(bool, true)
    manage_bucket       = optional(bool, true)
    lifecycle_rules = optional(list(object({
      id              = string
      enabled         = bool
      expiration_days = optional(number)
      transitions = optional(list(object({
        days          = number
        storage_class = string
      })))
    })))
  })
  default     = {}
  description = "AWS S3 configuration"

  validation {
    condition = !(
      try(var.aws.manage_bucket, true) == false &&
      length(try(trimspace(var.aws.bucket_name), "")) == 0
    )
    error_message = "When aws.manage_bucket is false you must provide aws.bucket_name."
  }

  validation {
    condition = (
      length(try(trimspace(var.aws.bucket_name), "")) == 0 ||
      try(trimspace(var.aws.bucket_name), "") ==
      lower(try(trimspace(var.aws.bucket_name), ""))
    )
    error_message = "aws.bucket_name must be lowercase."
  }
}

variable "secrets" {
  description = "Sensitive inputs (access keys, secret keys) supplied by the root module."
  type = object({
    access_key = optional(string)
    secret_key = optional(string)
  })
  default = {}
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
    project_id                  = optional(string)
    bucket_name                 = optional(string)
    location                    = optional(string, "US")
    storage_class               = optional(string, "STANDARD") # STANDARD, NEARLINE, COLDLINE, ARCHIVE
    uniform_bucket_level_access = optional(bool, true)
    versioning_enabled          = optional(bool, false)
    force_destroy               = optional(bool, true)
    kms_key_name                = optional(string)
    manage_bucket               = optional(bool, true)
    access_key                  = optional(string)
    secret_key                  = optional(string)
    lifecycle_rules = optional(list(object({
      action = object({
        type          = string
        storage_class = optional(string)
      })
      condition = object({
        age                   = optional(number)
        created_before        = optional(string)
        with_state            = optional(string)
        matches_storage_class = optional(list(string))
        num_newer_versions    = optional(number)
      })
    })), [])
    cors_rules = optional(list(object({
      origin          = list(string)
      method          = list(string)
      response_header = list(string)
      max_age_seconds = number
    })), [])
    labels = optional(map(string), {})
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
