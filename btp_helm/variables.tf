variable "chart_repository" {
  type    = string
  default = ""
}

variable "chart_name" {
  type    = string
  default = ""
}

variable "chart_version" {
  type    = string
  default = ""
}

variable "namespace" {
  type    = string
  default = "btp"
}

variable "values" {
  type    = map(any)
  default = {}
}

# Dependency inputs (normalized)
variable "postgres" { type = any }
variable "redis" { type = any }
variable "object_storage" { type = any }
variable "oauth" { type = any }
variable "secrets" { type = any }
variable "ingress_tls" { type = any }
variable "metrics_logs" { type = any }
