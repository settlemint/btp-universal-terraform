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
  default = "4.13.3"
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
  default     = false
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

variable "kubeconfig_path" {
  description = "Path to the kubeconfig file for kubectl commands"
  type        = string
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
