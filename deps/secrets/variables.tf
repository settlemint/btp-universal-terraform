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
    chart_version = optional(string, "0.30.1")
    release_name  = optional(string, "vault")
    values        = optional(map(any), {})
    dev_mode      = optional(bool, true)
    dev_token     = optional(string)
  })
  default     = {}
  description = "Kubernetes (Vault Helm chart) configuration"
}

# AWS-specific variables
variable "aws" {
  type = object({
    region = optional(string, "us-east-1")
  })
  default     = {}
  description = "AWS Secrets Manager configuration (IAM-based, typically no explicit config needed)"
}

# Azure-specific variables
variable "azure" {
  type = object({
    key_vault_name      = optional(string, "btp-keyvault")
    location            = optional(string)
    resource_group_name = optional(string)
    tenant_id           = optional(string)
    sku_name            = optional(string, "standard")
  })
  default     = {}
  description = "Azure Key Vault configuration"
}

# GCP-specific variables
variable "gcp" {
  type = object({
    project_id = optional(string)
  })
  default     = {}
  description = "GCP Secret Manager configuration (service account-based)"
}

# BYO-specific variables
variable "byo" {
  type = object({
    vault_addr = string
    token      = optional(string)
    kv_mount   = optional(string, "secret")
    paths      = optional(list(string), [])
  })
  default     = null
  description = "Bring-your-own Vault/secrets service configuration"
}
