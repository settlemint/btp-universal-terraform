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
    chart_version = optional(string, "22.0.7")
    release_name  = optional(string, "redis")
    values        = optional(map(any), {})
    password      = optional(string)
  })
  default     = {}
  description = "Kubernetes (Bitnami Helm chart) configuration"
}

# AWS-specific variables
variable "aws" {
  type = object({
    cluster_id                   = optional(string, "btp-redis")
    engine_version               = optional(string, "7.0")
    node_type                    = optional(string, "cache.t3.micro")
    parameter_group_name         = optional(string, "default.redis7")
    security_group_ids           = optional(list(string), [])
    subnet_group_name            = optional(string)
    auth_token                   = optional(string)
    transit_encryption_enabled   = optional(bool, false)
  })
  default     = {}
  description = "AWS ElastiCache configuration"
}

# Azure-specific variables
variable "azure" {
  type = object({
    cache_name          = optional(string, "btp-redis")
    location            = optional(string)
    resource_group_name = optional(string)
    capacity            = optional(number, 0)
    family              = optional(string, "C")
    sku_name            = optional(string, "Basic")
    ssl_enabled         = optional(bool, true)
    primary_access_key  = optional(string)
  })
  default     = {}
  description = "Azure Cache for Redis configuration"
}

# GCP-specific variables
variable "gcp" {
  type = object({
    instance_name            = optional(string, "btp-redis")
    tier                     = optional(string, "BASIC")
    memory_size_gb           = optional(number, 1)
    region                   = optional(string, "us-central1")
    redis_version            = optional(string, "REDIS_7_0")
    auth_string              = optional(string)
    transit_encryption_mode  = optional(string, "DISABLED")
  })
  default     = {}
  description = "GCP Memorystore configuration"
}

# BYO-specific variables
variable "byo" {
  type = object({
    host        = string
    port        = number
    password    = optional(string)
    scheme      = optional(string, "redis")
    tls_enabled = optional(bool, false)
  })
  default     = null
  description = "Bring-your-own Redis configuration (external endpoint)"
}
