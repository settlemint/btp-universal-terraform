variable "mode" {
  type        = string
  description = "Install mode. Only 'k8s' is supported in v1."
  default     = "k8s"
}

variable "namespace" {
  type        = string
  description = "Namespace for ingress and cert-manager components."
  default     = "btp-deps"
}

variable "nginx_chart_version" {
  type    = string
  default = "4.14.1"
}

variable "cert_manager_chart_version" {
  type    = string
  default = "v1.18.2"
}

variable "release_name_nginx" {
  type    = string
  default = "ingress"
}

variable "release_name_cert_manager" {
  type    = string
  default = "cert-manager"
}

variable "issuer_name" {
  type    = string
  default = "selfsigned-issuer"
}

variable "manage_namespace" {
  description = "Whether this module should create the namespace. Set false if namespaces are managed at root."
  type        = bool
  default     = true
}

variable "values_nginx" {
  description = "Additional values to merge into the ingress-nginx chart."
  type        = map(any)
  default     = {}
}

variable "values_cert_manager" {
  description = "Additional values to merge into the cert-manager chart."
  type        = map(any)
  default     = {}
}

variable "acme_environment" {
  description = "Let's Encrypt environment to use for ACME challenges. Valid options: production, staging."
  type        = string
  default     = "production"

  validation {
    condition     = contains(["production", "staging"], lower(var.acme_environment))
    error_message = "acme_environment must be either \"production\" or \"staging\"."
  }
}

variable "kubeconfig_path" {
  description = "Path to the kubeconfig file for kubectl commands"
  type        = string
}

variable "base_domain" {
  description = "Base domain used to derive default certificate names when none are provided."
  type        = string
  default     = null
}

variable "dns_context" {
  description = "DNS module outputs used for wildcard certificate wiring."
  type = object({
    hostname          = optional(string)
    wildcard_hostname = optional(string)
  })
  default = {}
}

variable "acme_email_candidates" {
  description = "Ordered list of fallback emails used when acme_email is not explicitly provided."
  type        = list(string)
  default     = []
}

variable "route53_zone_id" {
  description = "AWS Route53 hosted zone ID for DNS-01 ACME challenges. If provided, DNS-01 will be used instead of HTTP-01"
  type        = string
  default     = null
}

variable "aws_region" {
  description = "AWS region for Route53 DNS-01 challenges"
  type        = string
  default     = "us-east-1"
}

variable "route53_credentials_secret_name" {
  description = "Existing Kubernetes Secret name that stores Route53 credentials for DNS-01 challenges. Leave null to let the module manage credentials."
  type        = string
  default     = null
  nullable    = true
}

variable "cluster_name" {
  description = "Kubernetes cluster identifier used to narrow AWS load balancer lookups."
  type        = string
  default     = null
}

variable "lookup_load_balancer" {
  description = "Resolve the ingress load balancer DNS name via AWS once the controller is installed."
  type        = bool
  default     = false
}

variable "aws_access_key_id" {
  description = "AWS access key ID for Route53 DNS-01 challenges. When provided alongside aws_secret_access_key, a Kubernetes Secret will be created."
  type        = string
  default     = null
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS secret access key for Route53 DNS-01 challenges. When provided alongside aws_access_key_id, a Kubernetes Secret will be created."
  type        = string
  default     = null
  sensitive   = true
}

variable "acme_email" {
  description = "Contact email used for the ACME account (Let's Encrypt). Provide a deployment-specific address to receive expiry notices."
  type        = string
  default     = null
}

variable "default_certificate" {
  description = "Optional default TLS certificate for ingress-nginx. Supports injecting a wildcard cert so services without explicit TLS sections remain trusted."
  type = object({
    enabled     = optional(bool, true)
    secret_name = optional(string)
    hosts       = optional(list(string), [])
  })
  default  = null
  nullable = true
}

variable "load_balancer_service_name" {
  description = "Explicit Kubernetes Service name for the ingress controller when it differs from the chart default."
  type        = string
  default     = null
}

variable "load_balancer_tags" {
  description = "Additional AWS tag filters applied when resolving the ingress load balancer."
  type        = map(string)
  default     = {}
}
