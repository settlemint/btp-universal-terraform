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

variable "base_domain" {
  type        = string
  description = "Base domain for ingress (used for k8s mode)"
  default     = "127.0.0.1.nip.io"
}

# Kubernetes-specific variables
variable "k8s" {
  type = object({
    chart_version   = optional(string, "25.2.0")
    release_name    = optional(string, "keycloak")
    values          = optional(map(any), {})
    ingress_enabled = optional(bool, false)
    admin_password  = optional(string)
  })
  default     = {}
  description = "Kubernetes (Keycloak Helm chart) configuration"
}

# AWS-specific variables
variable "aws" {
  type = object({
    region         = optional(string, "us-east-1")
    user_pool_id   = optional(string)
    user_pool_name = optional(string, "btp-users")
    client_id      = optional(string)
    client_name    = optional(string, "btp-client")
    client_secret  = optional(string)
    callback_urls  = optional(list(string), [])
  })
  default     = {}
  description = "AWS Cognito configuration"
}

# Azure-specific variables
variable "azure" {
  type = object({
    tenant_id           = optional(string)
    tenant_name         = optional(string, "btptenant")
    resource_group_name = optional(string)
    location            = optional(string)
    domain_name         = optional(string)
    sku_name            = optional(string, "PremiumP1")
    client_id           = optional(string)
    client_secret       = optional(string)
    callback_urls       = optional(list(string), [])
  })
  default     = {}
  description = "Azure AD B2C configuration"
}

# GCP-specific variables
variable "gcp" {
  type = object({
    project_id    = optional(string)
    client_id     = optional(string)
    client_secret = optional(string)
    callback_urls = optional(list(string), [])
  })
  default     = {}
  description = "GCP Identity Platform configuration"
}

# BYO-specific variables
variable "byo" {
  type = object({
    issuer        = string
    admin_url     = optional(string)
    client_id     = optional(string)
    client_secret = optional(string)
    scopes        = optional(list(string), ["openid", "email", "profile"])
    callback_urls = optional(list(string), [])
  })
  default     = null
  description = "Bring-your-own OAuth/OIDC provider configuration"
}
