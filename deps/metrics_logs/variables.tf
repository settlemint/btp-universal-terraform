variable "mode" {
  type    = string
  default = "k8s"
}

variable "namespace" {
  type    = string
  default = "btp-deps"
}

variable "kp_stack_chart_version" {
  type    = string
  default = "77.10.0"
}

variable "loki_stack_chart_version" {
  type    = string
  default = "2.10.2"
}

variable "release_name_kps" {
  type    = string
  default = "kps"
}

variable "release_name_loki" {
  type    = string
  default = "loki"
}

variable "values" {
  type    = map(any)
  default = {}
}

variable "manage_namespace" {
  description = "Whether this module should create the namespace. Set false if namespaces are managed at root."
  type        = bool
  default     = false
}
