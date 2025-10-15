variable "mode" {
  description = "DNS provider mode: aws | azure | gcp | cf | byo"
  type        = string
  default     = "byo"

  validation {
    condition     = contains(["aws", "azure", "gcp", "cf", "byo"], var.mode)
    error_message = "Mode must be one of: aws, azure, gcp, cf, byo"
  }
}

variable "domain" {
  description = "Primary platform domain (e.g., platform.company.com)"
  type        = string
}

variable "release_name" {
  description = "Helm release name (used for default TLS secret naming when not provided explicitly)"
  type        = string
  default     = null
}

variable "enable_wildcard" {
  description = "Create wildcard (*.domain) DNS record alongside the primary record"
  type        = bool
  default     = true
}

variable "include_wildcard_in_tls" {
  description = "Include *.domain in TLS host outputs. Enable only when wildcard certificates are supported (e.g., Cloudflare Total TLS or DNS-01 challenges)."
  type        = bool
  default     = false
}

variable "cert_manager_issuer" {
  description = "cert-manager ClusterIssuer/Issuer name to annotate ingress resources with"
  type        = string
  default     = null
}

variable "tls_secret_name" {
  description = "TLS secret name to expose for ingress configuration. Defaults to <release_name>-tls when unset."
  type        = string
  default     = null
}

variable "ssl_redirect" {
  description = "Whether nginx.ingress.kubernetes.io/ssl-redirect should be enabled"
  type        = bool
  default     = false # Set to false to allow HTTP-01 ACME challenges for Let's Encrypt
}

variable "annotations" {
  description = "Additional annotations to merge into ingress resources"
  type        = map(string)
  default     = {}
}

variable "aws" {
  description = "AWS Route53 configuration when mode = \"aws\". Provide either main_record_value or alias."
  type = object({
    zone_id           = optional(string)
    zone_name         = optional(string)
    main_record_type  = optional(string, "A")
    main_record_value = optional(string)
    main_ttl          = optional(number, 300)
    alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = optional(bool, false)
      type                   = optional(string, "A")
    }))
    wildcard_record_type  = optional(string, "CNAME")
    wildcard_record_value = optional(string)
    wildcard_ttl          = optional(number, 300)
    wildcard_alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = optional(bool, false)
      type                   = optional(string, "A")
    }))
  })
  default = null
}

variable "azure" {
  description = "Azure DNS configuration when mode = \"azure\""
  type = object({
    resource_group_name   = string
    zone_name             = string
    main_record_type      = optional(string, "A")
    main_record_value     = string
    main_ttl              = optional(number, 300)
    wildcard_record_type  = optional(string, "CNAME")
    wildcard_record_value = optional(string)
    wildcard_ttl          = optional(number, 300)
  })
  default = null
}

variable "gcp" {
  description = "GCP Cloud DNS configuration when mode = \"gcp\""
  type = object({
    managed_zone          = string
    project               = optional(string)
    main_record_type      = optional(string, "A")
    main_record_value     = string
    main_ttl              = optional(number, 300)
    wildcard_record_type  = optional(string, "CNAME")
    wildcard_record_value = optional(string)
    wildcard_ttl          = optional(number, 300)
  })
  default = null
}

variable "cf" {
  description = "Cloudflare DNS configuration when mode = \"cf\""
  type = object({
    api_token             = optional(string)
    zone_id               = optional(string)
    zone_name             = optional(string)
    proxied               = optional(bool, true)
    main_record_type      = optional(string, "A")
    main_record_value     = string
    main_ttl              = optional(number, 300)
    wildcard_record_type  = optional(string, "CNAME")
    wildcard_record_value = optional(string)
    wildcard_ttl          = optional(number, 300)
  })
  default = null
}

variable "byo" {
  description = "Bring-your-own DNS configuration. No records are created; outputs are sourced from this object."
  type = object({
    ingress_annotations = optional(map(string), {})
    tls_secret_name     = optional(string)
    tls_hosts           = optional(list(string))
    ssl_redirect        = optional(bool)
  })
  default = null
}
