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
  default = "14.6.7"
}

variable "release_name" {
  type    = string
  default = "minio"
}

variable "values" {
  type    = map(any)
  default = {}
}

variable "default_bucket" {
  type    = string
  default = "btp-artifacts"
}

variable "manage_namespace" {
  description = "Whether this module should create the namespace. Set false if namespaces are managed at root."
  type        = bool
  default     = false
}
