variable "mode" {
  type        = string
  description = "Install mode. Only 'k8s' is supported in v1."
  default     = "k8s"
}

variable "namespace" {
  type    = string
  default = "btp-deps"
}

variable "operator_chart_version" {
  description = "Helm chart version for the Zalando Postgres Operator"
  type        = string
  default     = "1.14.0"
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

variable "postgresql_version" {
  description = "PostgreSQL major version for the cluster (e.g., '15' or '14')"
  type        = string
  default     = "15"
}

variable "credentials_secret_name_override" {
  description = "Override the name of the Secret that contains the 'postgres' user credentials. If null, uses the Zalando operator default pattern '<release>.postgres.credentials.postgresql.acid.zalan.do'."
  type        = string
  default     = null
}

variable "manage_namespace" {
  description = "Whether this module should create the namespace. Set false if namespaces are managed at root."
  type        = bool
  default     = false
}
