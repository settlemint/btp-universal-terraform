variable "mode" {
  type    = string
  default = "k8s"
}

variable "namespace" {
  type    = string
  default = "btp-deps"
}

variable "chart_version" {
  type    = string
  default = "25.2.0"
}

variable "release_name" {
  type    = string
  default = "keycloak"
}

variable "values" {
  type    = map(any)
  default = {}
}

variable "base_domain" {
  type    = string
  default = "127.0.0.1.nip.io"
}

variable "ingress_enabled" {
  description = "Enable ingress for Keycloak. Defaults to false for local/dev to avoid admission webhook races."
  type        = bool
  default     = false
}

variable "admin_password" {
  description = "Override Keycloak admin password; if null, a random value is generated"
  type        = string
  default     = null
}

variable "manage_namespace" {
  description = "Whether this module should create the namespace. Set false if namespaces are managed at root."
  type        = bool
  default     = false
}
