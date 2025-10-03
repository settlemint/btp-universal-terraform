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
  default = "0.30.1"
}

variable "release_name" {
  type    = string
  default = "vault"
}

variable "values" {
  type    = map(any)
  default = {}
}

variable "dev_mode" {
  type    = bool
  default = true
}

variable "dev_token" {
  description = "Vault dev root token to expose via outputs when dev_mode is true. Defaults to 'root' if null."
  type        = string
  default     = null
}

variable "manage_namespace" {
  description = "Whether this module should create the namespace. Set false if namespaces are managed at root."
  type        = bool
  default     = false
}
