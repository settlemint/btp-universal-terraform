variable "mode" {
  type        = string
  description = "Install mode. Only 'k8s' is supported in v1."
  default     = "k8s"
}

variable "namespace" {
  type    = string
  default = "btp-deps"
}

variable "chart_version" {
  type    = string
  default = "16.7.27"
}

variable "release_name" {
  type    = string
  default = "postgres"
}

variable "values" {
  type    = map(any)
  default = {}
}

variable "database" {
  type    = string
  default = "btp"
}

variable "manage_namespace" {
  description = "Whether this module should create the namespace. Set false if namespaces are managed at root."
  type        = bool
  default     = false
}
