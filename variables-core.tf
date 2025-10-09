# Core and Infrastructure configuration variables

variable "platform" {
  description = "Target platform: aws | azure | gcp | generic. OrbStack uses generic."
  type        = string
  default     = "generic"

  validation {
    condition     = contains(["aws", "azure", "gcp", "generic"], var.platform)
    error_message = "Platform must be one of: aws, azure, gcp, generic"
  }
}

variable "base_domain" {
  description = "Base domain for local ingress. Use 127.0.0.1.nip.io for OrbStack."
  type        = string
  default     = "127.0.0.1.nip.io"

  validation {
    condition     = can(regex("^[a-z0-9.-]+$", var.base_domain))
    error_message = "Base domain must be a valid domain name (lowercase alphanumeric, dots, and dashes only)"
  }
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
    ingress_tls    = optional(string)
    postgres       = optional(string)
    redis          = optional(string)
    object_storage = optional(string)
    metrics_logs   = optional(string)
    oauth          = optional(string)
    secrets        = optional(string)
  })
  default = {
    ingress_tls    = "btp-deps"
    postgres       = "btp-deps"
    redis          = "btp-deps"
    object_storage = "btp-deps"
    metrics_logs   = "btp-deps"
    oauth          = "btp-deps"
    secrets        = "btp-deps"
  }
}

# VPC configuration for AWS deployments
variable "vpc" {
  description = "VPC configuration for AWS platform"
  type = object({
    aws = optional(object({
      create_vpc                             = optional(bool, true)
      vpc_name                               = optional(string, "btp-vpc")
      vpc_cidr                               = optional(string, "10.0.0.0/16")
      region                                 = optional(string, "us-east-1")
      availability_zones                     = optional(list(string), ["us-east-1a", "us-east-1b", "us-east-1c"])
      enable_nat_gateway                     = optional(bool, true)
      single_nat_gateway                     = optional(bool, true)
      enable_s3_endpoint                     = optional(bool, true)
      additional_security_group_ids          = optional(list(string), [])
      existing_vpc_id                        = optional(string)
      existing_private_subnet_ids            = optional(list(string), [])
      existing_public_subnet_ids             = optional(list(string), [])
      existing_rds_security_group_id         = optional(string)
      existing_elasticache_security_group_id = optional(string)
    }), {})
  })
  default = {}
}

# Kubernetes Cluster configuration
variable "k8s_cluster" {
  description = "Managed Kubernetes cluster configuration (EKS, AKS, GKE) or BYO cluster"
  type = object({
    mode  = optional(string, "disabled") # aws | azure | gcp | byo | disabled
    aws   = optional(any, {})            # AWS EKS configuration (see deps/k8s_cluster/variables.tf)
    azure = optional(any, {})            # Azure AKS configuration
    gcp   = optional(any, {})            # GCP GKE configuration
    byo   = optional(any, null)          # Bring Your Own cluster (kubeconfig)
  })
  default = {}
}
