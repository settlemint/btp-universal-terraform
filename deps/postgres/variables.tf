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
  description = "Preferred Kubernetes namespace. Falls back to provider-specific namespace overrides when set."
  default     = "btp-deps"
}

variable "manage_namespace" {
  description = "Whether this module should create the namespace before provisioning Kubernetes resources."
  type        = bool
  default     = true
}

# Kubernetes-specific variables
variable "k8s" {
  type = object({
    operator_chart_version           = optional(string, "1.12.0")
    postgresql_version               = optional(string, "15")
    release_name                     = optional(string, "postgres")
    values                           = optional(map(any), {})
    database                         = optional(string, "btp")
    credentials_secret_name_override = optional(string)
    enable_ssl                       = optional(bool, false)
    pg_hba_rules = optional(list(string), [
      "host all all all md5",
      "local all all trust"
    ])
  })
  default     = {}
  description = "Kubernetes (Zalando Postgres Operator) configuration"
}

# AWS-specific variables
variable "aws" {
  type = object({
    identifier                      = optional(string, "btp-postgres")
    engine_version                  = optional(string, "15.4")
    instance_class                  = optional(string, "db.t3.micro")
    allocated_storage               = optional(number, 20)
    database                        = optional(string, "btp")
    username                        = optional(string, "postgres")
    password                        = optional(string)
    security_group_ids              = optional(list(string), [])
    subnet_ids                      = optional(list(string), [])
    subnet_group_name               = optional(string)
    skip_final_snapshot             = optional(bool, true)
    publicly_accessible             = optional(bool, false)
    backup_retention_period         = optional(number, 7)
    backup_window                   = optional(string, "03:00-04:00")
    storage_encrypted               = optional(bool, true)
    kms_key_id                      = optional(string)
    enabled_cloudwatch_logs_exports = optional(list(string), ["postgresql", "upgrade"])
    performance_insights_enabled    = optional(bool, false)
    auto_minor_version_upgrade      = optional(bool, true)
    maintenance_window              = optional(string, "mon:04:00-mon:05:00")
  })
  default     = {}
  description = "AWS RDS configuration"
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
    server_name         = optional(string, "btp-postgres")
    resource_group_name = optional(string)
    location            = optional(string)
    version             = optional(string, "15")
    sku_name            = optional(string, "B_Standard_B1ms")
    storage_mb          = optional(number, 32768)
    database            = optional(string, "btp")
    admin_username      = optional(string, "postgres")
    admin_password      = optional(string)
  })
  default     = {}
  description = "Azure Database for PostgreSQL configuration"
}

# GCP-specific variables
variable "gcp" {
  type = object({
    instance_name    = optional(string, "btp-postgres")
    database_version = optional(string, "POSTGRES_15")
    region           = optional(string, "us-central1")
    tier             = optional(string, "db-f1-micro")
    database         = optional(string, "btp")
    username         = optional(string, "postgres")
    password         = optional(string)
  })
  default     = {}
  description = "GCP Cloud SQL configuration"
}

# BYO-specific variables
variable "byo" {
  type = object({
    host     = string
    port     = number
    username = string
    password = string
    database = string
  })
  default     = null
  description = "Bring-your-own PostgreSQL configuration (external endpoint)"
}
