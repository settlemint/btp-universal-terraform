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
  default = "17.0.21"
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

variable "access_key" {
  description = "Override MinIO access key (rootUser); defaults to 'minio' if null"
  type        = string
  default     = null
}

variable "secret_key" {
  description = "Override MinIO secret key (rootPassword); if null, a random value is generated"
  type        = string
  default     = null
}

variable "manage_namespace" {
  description = "Whether this module should create the namespace. Set false if namespaces are managed at root."
  type        = bool
  default     = false
}
