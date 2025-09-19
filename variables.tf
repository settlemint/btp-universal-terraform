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
    ingress_tls    = optional(string, "btp-ingress")
    postgres       = optional(string, "btp-postgres")
    redis          = optional(string, "btp-redis")
    object_storage = optional(string, "btp-minio")
    metrics_logs   = optional(string, "btp-observability")
    oauth          = optional(string, "btp-oauth")
    secrets        = optional(string, "btp-secrets")
  })
  default = {}
}

# Dependency configs (k8s mode for v1)
variable "postgres" {
  type = object({
    mode = optional(string, "k8s")
    k8s = optional(object({
      namespace     = optional(string)
      chart_version = optional(string, "13.4.2")
      release_name  = optional(string, "postgres")
      values        = optional(map(any), {})
      database      = optional(string, "btp")
    }), {})
  })
  default = {}
}

variable "redis" {
  type = object({
    mode = optional(string, "k8s")
    k8s = optional(object({
      namespace     = optional(string)
      chart_version = optional(string, "18.1.6")
      release_name  = optional(string, "redis")
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
      chart_version  = optional(string, "14.6.7")
      release_name   = optional(string, "minio")
      values         = optional(map(any), {})
      default_bucket = optional(string, "btp-artifacts")
    }), {})
  })
  default = {}
}

variable "ingress_tls" {
  type = object({
    mode = optional(string, "k8s")
    k8s = optional(object({
      namespace                  = optional(string)
      nginx_chart_version        = optional(string, "4.10.1")
      cert_manager_chart_version = optional(string, "v1.14.4")
      release_name_nginx         = optional(string, "ingress")
      release_name_cert_manager  = optional(string, "cert-manager")
      issuer_name                = optional(string, "selfsigned-issuer")
    }), {})
  })
  default = {}
}

variable "metrics_logs" {
  type = object({
    mode = optional(string, "k8s")
    k8s = optional(object({
      namespace                = optional(string)
      kp_stack_chart_version   = optional(string, "55.8.2")
      loki_stack_chart_version = optional(string, "2.9.11")
      release_name_kps         = optional(string, "kps")
      release_name_loki        = optional(string, "loki")
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
      chart_version = optional(string, "22.3.2")
      release_name  = optional(string, "keycloak")
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
      chart_version = optional(string, "0.27.0")
      release_name  = optional(string, "vault")
      values        = optional(map(any), {})
      dev_mode      = optional(bool, true)
    }), {})
  })
  default = {}
}
