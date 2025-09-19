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
  default = "4.10.1"
}

variable "cert_manager_chart_version" {
  type    = string
  default = "v1.14.4"
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
