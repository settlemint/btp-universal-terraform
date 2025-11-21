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
    cluster_id                 = optional(string, "btp-redis")
    engine_version             = optional(string, "7.0")
    node_type                  = optional(string, "cache.t3.micro")
    num_cache_nodes            = optional(number, 1)
    parameter_group_name       = optional(string, "default.redis7")
    security_group_ids         = optional(list(string), [])
    subnet_ids                 = optional(list(string), [])
    subnet_group_name          = optional(string)
    auth_token                 = optional(string)
    transit_encryption_enabled = optional(bool, false)
    at_rest_encryption_enabled = optional(bool, true)
    maintenance_window         = optional(string, "sun:05:00-sun:06:00")
    snapshot_window            = optional(string, "03:00-04:00")
    snapshot_retention_limit   = optional(number, 5)
    auto_minor_version_upgrade = optional(bool, true)
    apply_immediately          = optional(bool, false)
    notification_topic_arn     = optional(string)
  })
  default     = {}
  description = "AWS ElastiCache configuration"
}

variable "aws_network" {
  description = "AWS networking context (typically derived from the VPC module)."
  type = object({
    subnet_ids         = optional(list(string), [])
    security_group_ids = optional(list(string), [])
    subnet_group_name  = optional(string)
  })
  default = {}
}

variable "secrets" {
  description = "Sensitive inputs (passwords, tokens) injected by the root module or secret manager."
  type = object({
    password = optional(string)
  })
  default = {}
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
    project_id              = optional(string)
    instance_name           = optional(string, "btp-redis")
    tier                    = optional(string, "BASIC") # BASIC or STANDARD_HA
    memory_size_gb          = optional(number, 1)
    region                  = optional(string, "us-central1")
    redis_version           = optional(string, "REDIS_7_0")
    display_name            = optional(string)
    reserved_ip_range       = optional(string)
    authorized_network      = optional(string)
    auth_enabled            = optional(bool, true)
    auth_string             = optional(string)
    transit_encryption_mode = optional(string, "DISABLED") # DISABLED or SERVER_AUTHENTICATION
    persistence_mode        = optional(string, "RDB")      # RDB or DISABLED (STANDARD_HA only)
    rdb_snapshot_period     = optional(string, "ONE_HOUR") # STANDARD_HA only
    maintenance_window_day  = optional(string, "MONDAY")
    maintenance_window_hour = optional(number, 3)
    redis_configs           = optional(map(string), {})
    labels                  = optional(map(string), {})
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
