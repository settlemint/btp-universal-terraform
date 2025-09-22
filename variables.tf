variable "platform" {
  description = "Target platform: aws | azure | gcp | generic. OrbStack uses generic."
  type        = string
  default     = "generic"
}

variable "base_domain" {
  description = "Base domain for local ingress. Use 127.0.0.1.nip.io for OrbStack."
  type        = string
  default     = "127.0.0.1.nip.io"
}

variable "cluster" {
  description = "Cluster connection configuration. For OrbStack/local, set create=false and use current kube context or provide kubeconfig_path."
  type = object({
    create          = optional(bool, false)
    name            = optional(string)
    version         = optional(string)
    region          = optional(string)
    node_groups     = optional(map(object({ instance_type = string, desired = number })), {})
    kubeconfig_path = optional(string)
  })
  default = {
    create          = false
    kubeconfig_path = null
  }
}

variable "namespaces" {
  description = "Namespaces per dependency (override to split)."
  type = object({
    ingress_tls    = optional(string, "btp-deps")
    postgres       = optional(string, "btp-deps")
    redis          = optional(string, "btp-deps")
    object_storage = optional(string, "btp-deps")
    metrics_logs   = optional(string, "btp-deps")
    oauth          = optional(string, "btp-deps")
    secrets        = optional(string, "btp-deps")
  })
  default = {}
}

# Dependency configs (k8s mode for v1)
variable "postgres" {
  type = object({
    mode = optional(string, "k8s")
    k8s = optional(object({
      namespace                        = optional(string)
      operator_chart_version           = optional(string)
      postgresql_version               = optional(string)
      release_name                     = optional(string)
      values                           = optional(map(any), {})
      database                         = optional(string)
      credentials_secret_name_override = optional(string)
    }), {})
  })
  default = {}
}

variable "redis" {
  type = object({
    mode = optional(string, "k8s")
    k8s = optional(object({
      namespace     = optional(string)
      chart_version = optional(string)
      release_name  = optional(string)
      values        = optional(map(any), {})
    }), {})
  })
  default = {}
}

variable "object_storage" {
  type = object({
    mode = optional(string, "k8s")
    k8s = optional(object({
      namespace      = optional(string)
      chart_version  = optional(string)
      release_name   = optional(string)
      values         = optional(map(any), {})
      default_bucket = optional(string)
    }), {})
  })
  default = {}
}

variable "ingress_tls" {
  type = object({
    mode = optional(string, "k8s")
    k8s = optional(object({
      namespace                  = optional(string)
      nginx_chart_version        = optional(string)
      cert_manager_chart_version = optional(string)
      release_name_nginx         = optional(string)
      release_name_cert_manager  = optional(string)
      issuer_name                = optional(string)
      values_nginx               = optional(map(any), {})
      values_cert_manager        = optional(map(any), {})
    }), {})
  })
  default = {}
}

variable "metrics_logs" {
  type = object({
    mode = optional(string, "k8s")
    k8s = optional(object({
      namespace                = optional(string)
      kp_stack_chart_version   = optional(string)
      loki_stack_chart_version = optional(string)
      release_name_kps         = optional(string)
      release_name_loki        = optional(string)
      values                   = optional(map(any), {})
    }), {})
  })
  default = {}
}

variable "oauth" {
  type = object({
    mode = optional(string, "k8s")
    k8s = optional(object({
      namespace     = optional(string)
      chart_version = optional(string)
      release_name  = optional(string)
      values        = optional(map(any), {})
    }), {})
  })
  default = {}
}

variable "secrets" {
  type = object({
    mode = optional(string, "k8s")
    k8s = optional(object({
      namespace     = optional(string)
      chart_version = optional(string)
      release_name  = optional(string)
      values        = optional(map(any), {})
      dev_mode      = optional(bool)
    }), {})
  })
  default = {}
}
