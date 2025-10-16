variable "mode" {
  type        = string
  description = "Deployment mode: aws | azure | gcp | byo | disabled"
  default     = "disabled"
  validation {
    condition     = contains(["aws", "azure", "gcp", "byo", "disabled"], var.mode)
    error_message = "Mode must be one of: aws, azure, gcp, byo, disabled"
  }
}

# AWS EKS-specific variables
variable "aws" {
  type = object({
    cluster_name    = optional(string, "btp-eks")
    cluster_version = optional(string, "1.31")
    region          = optional(string, "us-east-1")

    # VPC Configuration (from VPC module)
    vpc_id                   = optional(string)
    subnet_ids               = optional(list(string), [])
    control_plane_subnet_ids = optional(list(string), []) # For control plane, defaults to subnet_ids

    # Node Group Configuration
    node_groups = optional(map(object({
      desired_size   = optional(number, 2)
      min_size       = optional(number, 1)
      max_size       = optional(number, 4)
      instance_types = optional(list(string), ["t3.medium"])
      capacity_type  = optional(string, "ON_DEMAND") # or "SPOT"
      disk_size      = optional(number, 50)
      labels         = optional(map(string), {})
      taints = optional(list(object({
        key    = string
        value  = optional(string)
        effect = string
      })), [])
      })), {
      default = {
        desired_size   = 2
        min_size       = 1
        max_size       = 4
        instance_types = ["t3.medium"]
      }
    })

    # Cluster Addons
    enable_cluster_autoscaler           = optional(bool, false)
    enable_metrics_server               = optional(bool, true)
    enable_aws_load_balancer_controller = optional(bool, true)
    enable_ebs_csi_driver               = optional(bool, true)

    # Cluster Endpoint Access
    endpoint_private_access = optional(bool, true)
    endpoint_public_access  = optional(bool, true)
    public_access_cidrs     = optional(list(string), ["0.0.0.0/0"])

    # Logging
    enabled_cluster_log_types = optional(list(string), ["api", "audit", "authenticator", "controllerManager", "scheduler"])

    # Encryption
    enable_secrets_encryption = optional(bool, true)
    kms_key_arn               = optional(string)

    # OIDC Provider (for IRSA - IAM Roles for Service Accounts)
    enable_irsa = optional(bool, true)

    # Tags
    tags = optional(map(string), {})
  })
  default     = {}
  description = "AWS EKS configuration"
}

variable "aws_context" {
  description = "AWS networking context provided by the VPC module."
  type = object({
    vpc_id                   = optional(string)
    subnet_ids               = optional(list(string), [])
    control_plane_subnet_ids = optional(list(string), [])
    security_group_ids       = optional(list(string), [])
  })
  default = {}
}

# Azure AKS-specific variables
variable "azure" {
  type = object({
    cluster_name        = optional(string, "btp-aks")
    resource_group_name = optional(string, "btp-resources")
    location            = optional(string, "eastus")
    kubernetes_version  = optional(string, "1.31")
    dns_prefix          = optional(string, "btp-aks")

    # Network Configuration
    vnet_subnet_id    = optional(string)
    network_plugin    = optional(string, "azure") # or "kubenet"
    network_policy    = optional(string, "azure") # or "calico"
    service_cidr      = optional(string, "10.1.0.0/16")
    dns_service_ip    = optional(string, "10.1.0.10")
    load_balancer_sku = optional(string, "standard")

    # Default Node Pool
    default_node_pool = optional(object({
      name                = optional(string, "default")
      node_count          = optional(number, 2)
      min_count           = optional(number, 1)
      max_count           = optional(number, 4)
      enable_auto_scaling = optional(bool, true)
      vm_size             = optional(string, "Standard_D2s_v3")
      os_disk_size_gb     = optional(number, 50)
      availability_zones  = optional(list(string), ["1", "2", "3"])
      node_labels         = optional(map(string), {})
      node_taints         = optional(list(string), [])
    }), {})

    # Additional Node Pools
    additional_node_pools = optional(map(object({
      node_count          = optional(number, 2)
      min_count           = optional(number, 1)
      max_count           = optional(number, 4)
      enable_auto_scaling = optional(bool, true)
      vm_size             = optional(string, "Standard_D2s_v3")
      os_disk_size_gb     = optional(number, 50)
      availability_zones  = optional(list(string), ["1", "2", "3"])
      node_labels         = optional(map(string), {})
      node_taints         = optional(list(string), [])
    })), {})

    # Identity
    identity_type = optional(string, "SystemAssigned") # or "UserAssigned"

    # Monitoring
    enable_log_analytics       = optional(bool, false)
    log_analytics_workspace_id = optional(string)

    # RBAC
    enable_rbac                   = optional(bool, true)
    enable_azure_rbac             = optional(bool, true)
    enable_azure_active_directory = optional(bool, false)

    # Tags
    tags = optional(map(string), {})
  })
  default     = {}
  description = "Azure AKS configuration"
}

# GCP GKE-specific variables
variable "gcp" {
  type = object({
    cluster_name       = optional(string, "btp-gke")
    project_id         = optional(string)
    region             = optional(string, "us-central1")
    network            = optional(string, "default")
    subnetwork         = optional(string, "default")
    kubernetes_version = optional(string, "1.31")

    # Cluster Configuration
    remove_default_node_pool = optional(bool, true)
    initial_node_count       = optional(number, 1)

    # Node Pool Configuration
    node_pools = optional(map(object({
      node_count     = optional(number, 2)
      min_node_count = optional(number, 1)
      max_node_count = optional(number, 4)
      auto_scaling   = optional(bool, true)
      machine_type   = optional(string, "e2-medium")
      disk_size_gb   = optional(number, 50)
      disk_type      = optional(string, "pd-standard")
      preemptible    = optional(bool, false)
      spot           = optional(bool, false)
      node_labels    = optional(map(string), {})
      node_taints = optional(list(object({
        key    = string
        value  = string
        effect = string
      })), [])
      oauth_scopes = optional(list(string), [
        "https://www.googleapis.com/auth/cloud-platform"
      ])
      })), {
      default = {
        node_count     = 2
        min_node_count = 1
        max_node_count = 4
        machine_type   = "e2-medium"
      }
    })

    # Networking
    enable_private_nodes    = optional(bool, false)
    enable_private_endpoint = optional(bool, false)
    master_ipv4_cidr_block  = optional(string, "172.16.0.0/28")
    ip_allocation_policy = optional(object({
      cluster_secondary_range_name  = optional(string, "pods")
      services_secondary_range_name = optional(string, "services")
      cluster_ipv4_cidr_block       = optional(string)
      services_ipv4_cidr_block      = optional(string)
    }), {})

    # Addons
    enable_http_load_balancing        = optional(bool, true)
    enable_horizontal_pod_autoscaling = optional(bool, true)
    enable_network_policy             = optional(bool, true)

    # Monitoring & Logging
    enable_cloud_logging    = optional(bool, true)
    enable_cloud_monitoring = optional(bool, true)

    # Workload Identity
    enable_workload_identity = optional(bool, true)

    # Labels
    resource_labels = optional(map(string), {})
  })
  default     = {}
  description = "GCP GKE configuration"
}

# BYO (Bring Your Own) cluster configuration
variable "byo" {
  type = object({
    kubeconfig_path    = optional(string)
    kubeconfig_content = optional(string) # Base64 encoded kubeconfig
    context_name       = optional(string) # Specific context to use from kubeconfig
  })
  default     = null
  description = "Bring Your Own cluster configuration via kubeconfig"
}
