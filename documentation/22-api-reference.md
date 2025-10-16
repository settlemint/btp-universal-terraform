# API Reference

## Overview

This document provides a comprehensive API reference for the SettleMint BTP Universal Terraform project. It includes all available variables, outputs, modules, and configuration options.

## Table of Contents

- [Root Module Variables](#root-module-variables)
- [Root Module Outputs](#root-module-outputs)
- [Dependency Modules](#dependency-modules)
- [BTP Module](#btp-module)
- [Configuration Reference](#configuration-reference)
- [Terraform Resources](#terraform-resources)
- [Helm Charts](#helm-charts)
- [Environment Variables](#environment-variables)

## Root Module Variables

### Core Configuration

#### Platform Configuration
```hcl
variable "platform" {
  description = "Target platform for deployment (aws, azure, gcp, generic)"
  type        = string
  default     = "generic"
  
  validation {
    condition     = contains(["aws", "azure", "gcp", "generic"], var.platform)
    error_message = "Platform must be one of: aws, azure, gcp, generic."
  }
}

variable "base_domain" {
  description = "Base domain for the BTP platform"
  type        = string
  default     = "btp.example.com"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "dev"
}
```

#### Cluster Configuration
```hcl
variable "cluster" {
  description = "Kubernetes cluster configuration"
  type = object({
    create = bool
    name   = string
    region = string
    
    # Node group configuration
    node_groups = map(object({
      instance_types = list(string)
      min_size      = number
      max_size      = number
      desired_size  = number
      disk_size     = number
      disk_type     = string
    }))
    
    # Add-ons
    addons = object({
      aws_load_balancer_controller = bool
      aws_ebs_csi_driver          = bool
      aws_efs_csi_driver          = bool
      aws_cloudwatch_observability = bool
    })
  })
  
  default = {
    create = true
    name   = "btp-cluster"
    region = "us-east-1"
    
    node_groups = {
      main = {
        instance_types = ["t3.medium"]
        min_size      = 1
        max_size      = 5
        desired_size  = 2
        disk_size     = 50
        disk_type     = "gp3"
      }
    }
    
    addons = {
      aws_load_balancer_controller = true
      aws_ebs_csi_driver          = true
      aws_efs_csi_driver          = false
      aws_cloudwatch_observability = false
    }
  }
}
```

#### Namespace Configuration
```hcl
variable "namespaces" {
  description = "Kubernetes namespaces configuration"
  type = object({
    settlemint = object({
      create = bool
      name   = string
      labels = map(string)
    })
    btp_deps = object({
      create = bool
      name   = string
      labels = map(string)
    })
  })
  
  default = {
    settlemint = {
      create = true
      name   = "settlemint"
      labels = {
        name = "settlemint"
      }
    }
    btp_deps = {
      create = true
      name   = "btp-deps"
      labels = {
        name = "btp-deps"
      }
    }
  }
}
```

### Dependency Configuration

#### PostgreSQL Configuration
```hcl
variable "postgres" {
  description = "PostgreSQL dependency configuration"
  type = object({
    mode             = string
    namespace        = string
    manage_namespace = bool
    
    # Kubernetes mode
    k8s = object({
      chart_version = string
      release_name  = string
      password      = string
      
      # High availability
      architecture = string
      replica_count = number
      
      # Persistence
      persistence = object({
        enabled      = bool
        size         = string
        storageClass = string
      })
      
      # Database configuration
      database = object({
        type     = string
        host     = string
        port     = number
        database = string
        username = string
        password = string
      })
      
      # Custom values
      values = map(any)
    })
    
    # AWS mode
    aws = object({
      cluster_id                 = string
      engine_version             = string
      node_type                  = string
      num_cache_nodes            = number
      parameter_group_name       = string
      multi_az                   = bool
      automatic_failover_enabled = bool
      auth_token                 = string
      transit_encryption_enabled = bool
      at_rest_encryption_enabled = bool
      subnet_ids                 = list(string)
      security_group_ids         = list(string)
      snapshot_retention_limit   = number
      snapshot_window            = string
      maintenance_window         = string
      cluster_mode_enabled       = bool
      num_node_groups            = number
      replicas_per_node_group    = number
    })
    
    # Azure mode
    azure = object({
      cache_name          = string
      location            = string
      resource_group_name = string
      capacity            = number
      family              = string
      sku_name            = string
      enable_non_ssl_port = bool
      minimum_tls_version = string
      redis_configuration = map(string)
      subnet_id           = string
      enable_backup       = bool
      backup_frequency    = number
      backup_max_count    = number
    })
    
    # GCP mode
    gcp = object({
      instance_name  = string
      tier           = string
      memory_size_gb = number
      region         = string
      redis_version  = string
      authorized_network = string
      auth_enabled   = bool
      maintenance_policy = map(any)
      redis_configs  = map(string)
    })
    
    # BYO mode
    byo = object({
      host        = string
      port        = number
      password    = string
      scheme      = string
      tls_enabled = bool
    })
  })
}
```

#### Redis Configuration
```hcl
variable "redis" {
  description = "Redis dependency configuration"
  type = object({
    mode             = string
    namespace        = string
    manage_namespace = bool
    
    # Kubernetes mode
    k8s = object({
      chart_version = string
      release_name  = string
      password      = string
      
      # High availability
      architecture = string
      replica_count = number
      
      # Persistence
      persistence = object({
        enabled      = bool
        size         = string
        storageClass = string
      })
      
      # Security
      auth = object({
        enabled  = bool
        password = string
      })
      
      # TLS configuration
      tls = object({
        enabled = bool
      })
      
      # Custom values
      values = map(any)
    })
    
    # AWS mode
    aws = object({
      cluster_id                 = string
      engine_version             = string
      node_type                  = string
      num_cache_nodes            = number
      parameter_group_name       = string
      multi_az                   = bool
      automatic_failover_enabled = bool
      auth_token                 = string
      transit_encryption_enabled = bool
      at_rest_encryption_enabled = bool
      subnet_ids                 = list(string)
      security_group_ids         = list(string)
      snapshot_retention_limit   = number
      snapshot_window            = string
      maintenance_window         = string
      cluster_mode_enabled       = bool
      num_node_groups            = number
      replicas_per_node_group    = number
    })
    
    # Azure mode
    azure = object({
      cache_name          = string
      location            = string
      resource_group_name = string
      capacity            = number
      family              = string
      sku_name            = string
      enable_non_ssl_port = bool
      minimum_tls_version = string
      redis_configuration = map(string)
      subnet_id           = string
      enable_backup       = bool
      backup_frequency    = number
      backup_max_count    = number
    })
    
    # GCP mode
    gcp = object({
      instance_name  = string
      tier           = string
      memory_size_gb = number
      region         = string
      redis_version  = string
      authorized_network = string
      auth_enabled   = bool
      maintenance_policy = map(any)
      redis_configs  = map(string)
    })
    
    # BYO mode
    byo = object({
      host        = string
      port        = number
      password    = string
      scheme      = string
      tls_enabled = bool
    })
  })
}
```

#### Object Storage Configuration
```hcl
variable "object_storage" {
  description = "Object storage dependency configuration"
  type = object({
    mode             = string
    namespace        = string
    manage_namespace = bool
    base_domain      = string
    
    # Kubernetes mode
    k8s = object({
      namespace      = string
      chart_version  = string
      release_name   = string
      default_bucket = string
      access_key     = string
      secret_key     = string
      
      # High availability
      mode = string
      replicas = number
      
      # Persistence
      persistence = object({
        enabled      = bool
        size         = string
        storageClass = string
      })
      
      # Security
      auth = object({
        rootUser     = string
        rootPassword = string
      })
      
      # TLS configuration
      tls = object({
        enabled = bool
      })
      
      # Ingress configuration
      ingress = object({
        enabled = bool
        hosts   = list(string)
        tls     = list(object({
          secretName = string
          hosts      = list(string)
        }))
      })
      
      # Custom values
      values = map(any)
    })
    
    # AWS mode
    aws = object({
      bucket_name        = string
      region             = string
      versioning_enabled = bool
      access_key         = string
      secret_key         = string
      server_side_encryption_configuration = map(any)
      public_access_block_configuration = map(any)
      lifecycle_rule     = list(map(any))
      cors_rule          = list(map(any))
      versioning         = map(any)
    })
    
    # Azure mode
    azure = object({
      storage_account_name = string
      resource_group_name  = string
      location             = string
      account_tier         = string
      replication_type     = string
      container_name       = string
      container_access_type = string
      access_key           = string
      allow_nested_items_to_be_public = bool
      shared_access_key_enabled = bool
      account_kind         = string
      access_tier          = string
      network_rules        = map(any)
      lifecycle_rule       = list(map(any))
    })
    
    # GCP mode
    gcp = object({
      bucket_name   = string
      location      = string
      storage_class = string
      access_key    = string
      secret_key    = string
      uniform_bucket_level_access = bool
      public_access_prevention = string
      versioning_enabled = bool
      lifecycle_rule = list(map(any))
      cors          = list(map(any))
      encryption    = map(any)
    })
    
    # BYO mode
    byo = object({
      endpoint       = string
      bucket         = string
      region         = string
      access_key     = string
      secret_key     = string
      use_path_style = bool
      force_path_style = bool
      s3_force_path_style = bool
    })
  })
}
```

#### OAuth Configuration
```hcl
variable "oauth" {
  description = "OAuth dependency configuration"
  type = object({
    mode             = string
    namespace        = string
    manage_namespace = bool
    base_domain      = string
    
    # Kubernetes mode
    k8s = object({
      namespace      = string
      chart_version  = string
      release_name   = string
      realm_name     = string
      admin_username = string
      admin_password = string
      
      # Database configuration
      database = object({
        type     = string
        host     = string
        port     = number
        database = string
        username = string
        password = string
      })
      
      # High availability
      replica_count = number
      
      # Persistence
      persistence = object({
        enabled      = bool
        size         = string
        storageClass = string
      })
      
      # Ingress configuration
      ingress = object({
        enabled = bool
        hosts   = list(string)
        tls     = list(object({
          secretName = string
          hosts      = list(string)
        }))
      })
      
      # Custom values
      values = map(any)
    })
    
    # AWS mode
    aws = object({
      user_pool_name = string
      region         = string
      username_attributes = list(string)
      auto_verified_attributes = list(string)
      mfa_configuration = string
      password_policy = map(any)
      client_name    = string
      client_settings = map(any)
      domain         = string
      identity_providers = list(map(any))
      user_pool_groups = list(map(any))
    })
    
    # Azure mode
    azure = object({
      tenant_name = string
      location    = string
      sku_name    = string
      access_policies = list(map(any))
      network_acls = map(any)
      soft_delete_retention_days = number
      purge_protection_enabled = bool
      secrets     = list(map(any))
      keys        = list(map(any))
      certificates = list(map(any))
    })
    
    # GCP mode
    gcp = object({
      project_id = string
      region     = string
      identity_platform = map(any)
      oauth_consent_screen = map(any)
      oauth_client = map(any)
      identity_providers = list(map(any))
    })
    
    # BYO mode
    byo = object({
      issuer_url = string
      client_id  = string
      client_secret = string
      realm     = string
      admin_username = string
      admin_password = string
      oidc_config = map(any)
      claims_mapping = map(string)
    })
  })
}
```

#### Secrets Configuration
```hcl
variable "secrets" {
  description = "Secrets dependency configuration"
  type = object({
    mode             = string
    namespace        = string
    manage_namespace = bool
    base_domain      = string
    
    # Kubernetes mode
    k8s = object({
      namespace     = string
      chart_version = string
      release_name  = string
      
      # High availability
      ha = object({
        enabled  = bool
        replicas = number
        raft     = object({
          enabled = bool
        })
      })
      
      # Consul backend
      consul = object({
        enabled = bool
        address = string
        path    = string
      })
      
      # Ingress configuration
      ingress = object({
        enabled = bool
        hosts   = list(string)
        tls     = list(object({
          secretName = string
          hosts      = list(string)
        }))
      })
      
      # Service configuration
      service = object({
        type = string
        port = number
      })
      
      # Custom values
      values = map(any)
    })
    
    # AWS mode
    aws = object({
      region = string
      secrets = list(object({
        name = string
        description = string
        secret_string = string
        rotation_config = object({
          enabled = bool
          rotation_lambda_arn = string
          rotation_days = number
        })
      }))
      kms_key_id = string
      resource_policy = string
    })
    
    # Azure mode
    azure = object({
      key_vault_name = string
      resource_group_name = string
      location = string
      sku_name = string
      access_policies = list(map(any))
      network_acls = map(any)
      soft_delete_retention_days = number
      purge_protection_enabled = bool
      secrets = list(map(any))
      keys    = list(map(any))
      certificates = list(map(any))
    })
    
    # GCP mode
    gcp = object({
      project_id = string
      region     = string
      secrets    = list(object({
        name = string
        secret_data = string
        labels = map(string)
        rotation_config = object({
          enabled = bool
          rotation_period = string
          next_rotation_time = string
        })
      }))
      iam_bindings = list(map(any))
      replication  = map(any)
    })
    
    # BYO mode
    byo = object({
      endpoint    = string
      token       = string
      namespace   = string
      engine      = string
      admin_token = string
      auth_config = map(any)
      tls_config  = map(any)
    })
  })
}
```

#### Observability Configuration
```hcl
variable "metrics_logs" {
  description = "Observability dependency configuration"
  type = object({
    mode             = string
    namespace        = string
    manage_namespace = bool
    base_domain      = string
    
    # Kubernetes mode
    k8s = object({
      namespace = string
      
      # Prometheus configuration
      prometheus = object({
        chart_version = string
        release_name  = string
        replica_count = number
        persistence   = map(any)
        ingress       = map(any)
        values        = map(any)
      })
      
      # Grafana configuration
      grafana = object({
        chart_version = string
        release_name  = string
        admin_user    = string
        admin_password = string
        persistence   = map(any)
        ingress       = map(any)
        values        = map(any)
      })
      
      # Loki configuration
      loki = object({
        chart_version = string
        release_name  = string
        replica_count = number
        persistence   = map(any)
        ingress       = map(any)
        values        = map(any)
      })
    })
    
    # AWS mode
    aws = object({
      region = string
      log_groups = list(map(any))
      alarms    = list(map(any))
      dashboards = list(map(any))
      xray      = map(any)
    })
    
    # Azure mode
    azure = object({
      resource_group_name = string
      location = string
      log_analytics_workspace = map(any)
      application_insights = map(any)
      alerts = list(map(any))
      dashboards = list(map(any))
    })
    
    # GCP mode
    gcp = object({
      project_id = string
      region     = string
      logging    = map(any)
      monitoring = map(any)
      trace      = map(any)
      profiler   = map(any)
      dashboards = list(map(any))
    })
    
    # BYO mode
    byo = object({
      prometheus = map(any)
      grafana    = map(any)
      loki       = map(any)
      custom     = map(any)
    })
  })
}
```

### BTP Platform Configuration

#### BTP Configuration
```hcl
variable "btp" {
  description = "BTP platform configuration"
  type = object({
    enabled = bool
    namespace = string
    chart = string
    chart_version = string
    release_name = string
    values = map(any)
    values_file = string
    deployment_namespace = string
  })
  
  default = {
    enabled = true
    namespace = "settlemint"
    chart = "btp-platform"
    chart_version = "latest"
    release_name = "btp-platform"
    values = {}
    values_file = ""
    deployment_namespace = "settlemint"
  }
}
```

### License Configuration

#### License Variables
```hcl
variable "license_username" {
  description = "License username"
  type        = string
  default     = ""
}

variable "license_password" {
  description = "License password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "license_signature" {
  description = "License signature"
  type        = string
  default     = ""
  sensitive   = true
}

variable "license_email" {
  description = "License email"
  type        = string
  default     = ""
}

variable "license_expiration_date" {
  description = "License expiration date"
  type        = string
  default     = ""
}
```

### Security Configuration

#### Security Variables
```hcl
variable "jwt_signing_key" {
  description = "JWT signing key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ipfs_cluster_secret" {
  description = "IPFS cluster secret"
  type        = string
  default     = ""
  sensitive   = true
}

variable "state_encryption_key" {
  description = "State encryption key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_access_key_id" {
  description = "AWS access key ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS secret access key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "google_oauth_client_id" {
  description = "Google OAuth client ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "google_oauth_client_secret" {
  description = "Google OAuth client secret"
  type        = string
  default     = ""
  sensitive   = true
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  default     = ""
  sensitive   = true
}
```

## Root Module Outputs

### Platform Outputs

#### Cluster Information
```hcl
output "cluster_info" {
  description = "Kubernetes cluster information"
  value = {
    name     = local.cluster_name
    endpoint = local.cluster_endpoint
    region   = local.cluster_region
    version  = local.cluster_version
  }
}

output "cluster_endpoint" {
  description = "Kubernetes cluster endpoint"
  value       = local.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "Kubernetes cluster CA certificate"
  value       = local.cluster_ca_certificate
  sensitive   = true
}
```

#### Dependency Outputs
```hcl
output "postgres" {
  description = "PostgreSQL connection details"
  value = {
    host     = module.postgres.host
    port     = module.postgres.port
    username = module.postgres.username
    password = module.postgres.password
    database = module.postgres.database
  }
  sensitive = true
}

output "redis" {
  description = "Redis connection details"
  value = {
    host        = module.redis.host
    port        = module.redis.port
    password    = module.redis.password
    scheme      = module.redis.scheme
    tls_enabled = module.redis.tls_enabled
  }
  sensitive = true
}

output "object_storage" {
  description = "Object storage connection details"
  value = {
    endpoint       = module.object_storage.endpoint
    bucket         = module.object_storage.bucket
    access_key     = module.object_storage.access_key
    secret_key     = module.object_storage.secret_key
    region         = module.object_storage.region
    use_path_style = module.object_storage.use_path_style
  }
  sensitive = true
}

output "oauth" {
  description = "OAuth connection details"
  value = {
    issuer_url     = local.oauth_outputs.issuer_url
    client_id      = local.oauth_outputs.client_id
    client_secret  = local.oauth_outputs.client_secret
    realm          = local.oauth_outputs.realm
    admin_username = local.oauth_outputs.admin_username
    admin_password = local.oauth_outputs.admin_password
  }
  sensitive = true
}

output "secrets" {
  description = "Secrets management connection details"
  value = {
    endpoint     = module.secrets.endpoint
    token        = module.secrets.token
    namespace    = module.secrets.namespace
    engine       = module.secrets.engine
    admin_token  = module.secrets.admin_token
  }
  sensitive = true
}

output "metrics_logs" {
  description = "Observability connection details"
  value = {
    prometheus_url    = module.metrics_logs.prometheus_url
    grafana_url       = module.metrics_logs.grafana_url
    loki_url          = module.metrics_logs.loki_url
    metrics_endpoint  = module.metrics_logs.metrics_endpoint
    logs_endpoint     = module.metrics_logs.logs_endpoint
  }
}
```

#### Platform URLs
```hcl
output "post_deploy_urls" {
  description = "Post-deployment URLs"
  value = {
    platform_url    = "https://${var.base_domain}"
    api_url         = "https://api.${var.base_domain}"
    auth_url        = "https://auth.${var.base_domain}"
    grafana_url     = "https://grafana.${var.base_domain}"
    prometheus_url  = "https://prometheus.${var.base_domain}"
  }
}

output "post_deploy_message" {
  description = "Post-deployment message"
  value = <<-EOT
    🎉 BTP Platform deployed successfully!
    
    📋 Access URLs:
    • Platform: https://${var.base_domain}
    • API: https://api.${var.base_domain}
    • Auth: https://auth.${var.base_domain}
    • Grafana: https://grafana.${var.base_domain}
    • Prometheus: https://prometheus.${var.base_domain}
    
    🔑 Admin credentials:
    • Grafana: admin / ${var.grafana_admin_password}
    
    📊 Next steps:
    1. Configure your domain DNS to point to the load balancer
    2. Update SSL certificates if needed
    3. Configure OAuth providers
    4. Set up monitoring alerts
    5. Review security settings
    
    📚 Documentation: https://docs.settlemint.com/btp
  EOT
}
```

## Dependency Modules

### PostgreSQL Module

#### Module Interface
```hcl
module "postgres" {
  source = "./deps/postgres"
  
  # Configuration
  mode             = var.postgres.mode
  namespace        = var.postgres.namespace
  manage_namespace = var.postgres.manage_namespace
  
  # Provider-specific configurations
  k8s   = var.postgres.k8s
  aws   = var.postgres.aws
  azure = var.postgres.azure
  gcp   = var.postgres.gcp
  byo   = var.postgres.byo
}
```

#### Module Outputs
```hcl
output "host" {
  description = "PostgreSQL host"
  value       = local.host
}

output "port" {
  description = "PostgreSQL port"
  value       = local.port
}

output "username" {
  description = "PostgreSQL username"
  value       = local.username
}

output "password" {
  description = "PostgreSQL password"
  value       = local.password
  sensitive   = true
}

output "database" {
  description = "PostgreSQL database name"
  value       = local.database
}

output "connection_string" {
  description = "PostgreSQL connection string"
  value       = local.connection_string
  sensitive   = true
}
```

### Redis Module

#### Module Interface
```hcl
module "redis" {
  source = "./deps/redis"
  
  # Configuration
  mode             = var.redis.mode
  namespace        = var.redis.namespace
  manage_namespace = var.redis.manage_namespace
  
  # Provider-specific configurations
  k8s   = var.redis.k8s
  aws   = var.redis.aws
  azure = var.redis.azure
  gcp   = var.redis.gcp
  byo   = var.redis.byo
}
```

#### Module Outputs
```hcl
output "host" {
  description = "Redis host"
  value       = local.host
}

output "port" {
  description = "Redis port"
  value       = local.port
}

output "password" {
  description = "Redis password"
  value       = local.password
  sensitive   = true
}

output "scheme" {
  description = "Redis connection scheme"
  value       = local.scheme
}

output "tls_enabled" {
  description = "Whether TLS is enabled"
  value       = local.tls_enabled
}
```

### Object Storage Module

#### Module Interface
```hcl
module "object_storage" {
  source = "./deps/object_storage"
  
  # Configuration
  mode             = var.object_storage.mode
  namespace        = var.object_storage.namespace
  manage_namespace = var.object_storage.manage_namespace
  base_domain      = var.object_storage.base_domain
  
  # Provider-specific configurations
  k8s   = var.object_storage.k8s
  aws   = var.object_storage.aws
  azure = var.object_storage.azure
  gcp   = var.object_storage.gcp
  byo   = var.object_storage.byo
}
```

#### Module Outputs
```hcl
output "endpoint" {
  description = "Object storage endpoint URL"
  value       = local.endpoint
}

output "bucket" {
  description = "Object storage bucket name"
  value       = local.bucket
}

output "access_key" {
  description = "Object storage access key"
  value       = local.access_key
  sensitive   = true
}

output "secret_key" {
  description = "Object storage secret key"
  value       = local.secret_key
  sensitive   = true
}

output "region" {
  description = "Object storage region"
  value       = local.region
}

output "use_path_style" {
  description = "Whether to use path-style URLs"
  value       = local.use_path_style
}
```

### OAuth Module

#### Module Interface
```hcl
module "oauth" {
  source = "./deps/oauth"
  
  # Configuration
  mode             = var.oauth.mode
  namespace        = var.oauth.namespace
  manage_namespace = var.oauth.manage_namespace
  base_domain      = var.oauth.base_domain
  
  # Provider-specific configurations
  k8s   = var.oauth.k8s
  aws   = var.oauth.aws
  azure = var.oauth.azure
  gcp   = var.oauth.gcp
  byo   = var.oauth.byo
}
```

#### Module Outputs
```hcl
output "issuer_url" {
  description = "OAuth issuer URL"
  value       = local.issuer_url
}

output "client_id" {
  description = "OAuth client ID"
  value       = local.client_id
}

output "client_secret" {
  description = "OAuth client secret"
  value       = local.client_secret
  sensitive   = true
}

output "realm" {
  description = "OAuth realm"
  value       = local.realm
}

output "admin_username" {
  description = "OAuth admin username"
  value       = local.admin_username
}

output "admin_password" {
  description = "OAuth admin password"
  value       = local.admin_password
  sensitive   = true
}
```

### Secrets Module

#### Module Interface
```hcl
module "secrets" {
  source = "./deps/secrets"
  
  # Configuration
  mode             = var.secrets.mode
  namespace        = var.secrets.namespace
  manage_namespace = var.secrets.manage_namespace
  base_domain      = var.secrets.base_domain
  
  # Provider-specific configurations
  k8s   = var.secrets.k8s
  aws   = var.secrets.aws
  azure = var.secrets.azure
  gcp   = var.secrets.gcp
  byo   = var.secrets.byo
}
```

#### Module Outputs
```hcl
output "endpoint" {
  description = "Secrets management endpoint URL"
  value       = local.endpoint
}

output "token" {
  description = "Secrets management access token"
  value       = local.token
  sensitive   = true
}

output "namespace" {
  description = "Secrets management namespace"
  value       = local.namespace
}

output "engine" {
  description = "Secrets management engine/path"
  value       = local.engine
}

output "admin_token" {
  description = "Secrets management admin token"
  value       = local.admin_token
  sensitive   = true
}
```

### Observability Module

#### Module Interface
```hcl
module "metrics_logs" {
  source = "./deps/metrics_logs"
  
  # Configuration
  mode             = var.metrics_logs.mode
  namespace        = var.metrics_logs.namespace
  manage_namespace = var.metrics_logs.manage_namespace
  base_domain      = var.metrics_logs.base_domain
  
  # Provider-specific configurations
  k8s   = var.metrics_logs.k8s
  aws   = var.metrics_logs.aws
  azure = var.metrics_logs.azure
  gcp   = var.metrics_logs.gcp
  byo   = var.metrics_logs.byo
}
```

#### Module Outputs
```hcl
output "prometheus_url" {
  description = "Prometheus URL"
  value       = local.prometheus_url
}

output "grafana_url" {
  description = "Grafana URL"
  value       = local.grafana_url
}

output "loki_url" {
  description = "Loki URL"
  value       = local.loki_url
}

output "metrics_endpoint" {
  description = "Metrics endpoint URL"
  value       = local.metrics_endpoint
}

output "logs_endpoint" {
  description = "Logs endpoint URL"
  value       = local.logs_endpoint
}
```

## BTP Module

### Module Interface
```hcl
module "btp" {
  source = "./btp"
  
  # Chart configuration
  chart                = var.btp.chart
  chart_version        = var.btp.chart_version
  namespace            = var.btp.namespace
  deployment_namespace = var.btp.deployment_namespace
  release_name         = var.btp.release_name
  values               = var.btp.values
  values_file          = var.btp.values_file
  create_namespace     = true
  
  # Base domain
  base_domain = var.base_domain
  
  # Dependency outputs
  postgres       = module.postgres
  redis          = module.redis
  object_storage = module.object_storage
  oauth          = local.oauth_outputs
  secrets        = module.secrets
  ingress_tls    = module.ingress_tls
  metrics_logs   = module.metrics_logs
  dns            = module.dns
  
  # License configuration
  license_username        = var.license_username
  license_password        = var.license_password
  license_signature       = var.license_signature
  license_email           = var.license_email
  license_expiration_date = var.license_expiration_date
  
  # Platform security secrets
  jwt_signing_key       = var.jwt_signing_key
  ipfs_cluster_secret   = var.ipfs_cluster_secret
  state_encryption_key  = var.state_encryption_key
  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  
  # Google OAuth
  google_oauth_client_id     = var.google_oauth_client_id
  google_oauth_client_secret = var.google_oauth_client_secret
  
  # Grafana admin password
  grafana_admin_password = var.grafana_admin_password
}
```

### Module Outputs
```hcl
output "platform_url" {
  description = "BTP platform URL"
  value       = "https://${var.base_domain}"
}

output "api_url" {
  description = "BTP API URL"
  value       = "https://api.${var.base_domain}"
}

output "auth_url" {
  description = "BTP auth URL"
  value       = "https://auth.${var.base_domain}"
}

output "grafana_url" {
  description = "Grafana URL"
  value       = "https://grafana.${var.base_domain}"
}

output "prometheus_url" {
  description = "Prometheus URL"
  value       = "https://prometheus.${var.base_domain}"
}
```

## Configuration Reference

### Environment Variables

#### Terraform Variables
```bash
# Platform configuration
export TF_VAR_platform="aws"
export TF_VAR_base_domain="btp.example.com"
export TF_VAR_environment="production"

# License configuration
export TF_VAR_license_username="your-license-username"
export TF_VAR_license_password="your-license-password"
export TF_VAR_license_signature="your-license-signature"
export TF_VAR_license_email="your-license-email"
export TF_VAR_license_expiration_date="2024-12-31"

# Security secrets
export TF_VAR_jwt_signing_key="your-jwt-signing-key"
export TF_VAR_ipfs_cluster_secret="your-ipfs-cluster-secret"
export TF_VAR_state_encryption_key="your-state-encryption-key"
export TF_VAR_aws_access_key_id="your-aws-access-key-id"
export TF_VAR_aws_secret_access_key="your-aws-secret-access-key"
export TF_VAR_google_oauth_client_id="your-google-oauth-client-id"
export TF_VAR_google_oauth_client_secret="your-google-oauth-client-secret"
export TF_VAR_grafana_admin_password="your-grafana-admin-password"

# Database passwords
export TF_VAR_postgres_password="your-postgres-password"
export TF_VAR_redis_password="your-redis-password"
export TF_VAR_object_storage_access_key="your-object-storage-access-key"
export TF_VAR_object_storage_secret_key="your-object-storage-secret-key"
export TF_VAR_oauth_admin_password="your-oauth-admin-password"
```

#### Kubernetes Environment Variables
```bash
# Kubernetes configuration
export KUBECONFIG="$HOME/.kube/config"
export KUBE_NAMESPACE="settlemint"

# Helm configuration
export HELM_REPO_UPDATE="true"
export HELM_TIMEOUT="300s"
```

### Configuration Files

#### Terraform Configuration
```hcl
# main.tf
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

# Configure providers
provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = module.cluster.endpoint
  cluster_ca_certificate = base64decode(module.cluster.kubeconfig_certificate_authority_data)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.cluster.name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.cluster.endpoint
    cluster_ca_certificate = base64decode(module.cluster.kubeconfig_certificate_authority_data)
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.cluster.name]
    }
  }
}
```

#### Variable Files
```hcl
# variables.tf
variable "platform" {
  description = "Target platform for deployment"
  type        = string
  default     = "aws"
}

variable "base_domain" {
  description = "Base domain for the BTP platform"
  type        = string
  default     = "btp.example.com"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

# ... (additional variables as defined above)
```

#### Output Files
```hcl
# outputs.tf
output "cluster_info" {
  description = "Kubernetes cluster information"
  value = {
    name     = module.cluster.name
    endpoint = module.cluster.endpoint
    region   = module.cluster.region
  }
}

output "platform_urls" {
  description = "Platform URLs"
  value = {
    platform_url   = "https://${var.base_domain}"
    api_url        = "https://api.${var.base_domain}"
    auth_url       = "https://auth.${var.base_domain}"
    grafana_url    = "https://grafana.${var.base_domain}"
    prometheus_url = "https://prometheus.${var.base_domain}"
  }
}

# ... (additional outputs as defined above)
```

## Terraform Resources

### Kubernetes Resources

#### Namespaces
```hcl
resource "kubernetes_namespace" "settlemint" {
  count = var.namespaces.settlemint.create ? 1 : 0
  
  metadata {
    name   = var.namespaces.settlemint.name
    labels = var.namespaces.settlemint.labels
  }
}

resource "kubernetes_namespace" "btp_deps" {
  count = var.namespaces.btp_deps.create ? 1 : 0
  
  metadata {
    name   = var.namespaces.btp_deps.name
    labels = var.namespaces.btp_deps.labels
  }
}
```

#### ConfigMaps
```hcl
resource "kubernetes_config_map" "btp_config" {
  metadata {
    name      = "btp-config"
    namespace = kubernetes_namespace.settlemint[0].metadata[0].name
  }
  
  data = {
    "config.yaml" = yamlencode({
      app = {
        name = "btp-platform"
        version = "latest"
        environment = var.environment
      }
      
      database = {
        host = module.postgres.host
        port = module.postgres.port
        name = module.postgres.database
        username = module.postgres.username
      }
      
      redis = {
        host = module.redis.host
        port = module.redis.port
        password = module.redis.password
      }
      
      object_storage = {
        endpoint = module.object_storage.endpoint
        bucket = module.object_storage.bucket
        access_key = module.object_storage.access_key
        secret_key = module.object_storage.secret_key
      }
      
      oauth = {
        issuer = module.oauth.issuer_url
        client_id = module.oauth.client_id
        client_secret = module.oauth.client_secret
      }
      
      secrets = {
        endpoint = module.secrets.endpoint
        token = module.secrets.token
        namespace = module.secrets.namespace
      }
    })
  }
}
```

#### Secrets
```hcl
resource "kubernetes_secret" "btp_secrets" {
  metadata {
    name      = "btp-secrets"
    namespace = kubernetes_namespace.settlemint[0].metadata[0].name
  }
  
  data = {
    postgres-password = module.postgres.password
    redis-password    = module.redis.password
    minio-access-key  = module.object_storage.access_key
    minio-secret-key  = module.object_storage.secret_key
    oauth-client-secret = module.oauth.client_secret
    vault-token       = module.secrets.token
    jwt-signing-key   = var.jwt_signing_key
  }
  
  type = "Opaque"
}
```

### Helm Resources

#### BTP Platform
```hcl
resource "helm_release" "btp_platform" {
  count = var.btp.enabled ? 1 : 0
  
  name       = var.btp.release_name
  repository = "https://charts.settlemint.com"
  chart      = var.btp.chart
  version    = var.btp.chart_version
  namespace  = var.btp.namespace
  
  create_namespace = true
  
  values = [
    yamlencode({
      app = {
        name = "btp-platform"
        version = "latest"
        environment = var.environment
      }
      
      image = {
        repository = "settlemint/btp-platform"
        tag = "latest"
        pullPolicy = "IfNotPresent"
      }
      
      service = {
        type = "ClusterIP"
        port = 8080
      }
      
      ingress = {
        enabled = true
        className = "nginx"
        hosts = [
          {
            host = var.base_domain
            paths = [
              {
                path = "/"
                pathType = "Prefix"
              }
            ]
          }
        ]
        tls = [
          {
            secretName = "btp-tls"
            hosts = [var.base_domain]
          }
        ]
      }
      
      resources = {
        requests = {
          memory = "512Mi"
          cpu = "500m"
        }
        limits = {
          memory = "1Gi"
          cpu = "1000m"
        }
      }
      
      env = [
        {
          name = "DATABASE_HOST"
          value = module.postgres.host
        },
        {
          name = "DATABASE_PORT"
          value = module.postgres.port
        },
        {
          name = "DATABASE_NAME"
          value = module.postgres.database
        },
        {
          name = "DATABASE_USERNAME"
          value = module.postgres.username
        },
        {
          name = "DATABASE_PASSWORD"
          valueFrom = {
            secretKeyRef = {
              name = "btp-secrets"
              key = "postgres-password"
            }
          }
        },
        {
          name = "REDIS_HOST"
          value = module.redis.host
        },
        {
          name = "REDIS_PORT"
          value = module.redis.port
        },
        {
          name = "REDIS_PASSWORD"
          valueFrom = {
            secretKeyRef = {
              name = "btp-secrets"
              key = "redis-password"
            }
          }
        },
        {
          name = "OBJECT_STORAGE_ENDPOINT"
          value = module.object_storage.endpoint
        },
        {
          name = "OBJECT_STORAGE_BUCKET"
          value = module.object_storage.bucket
        },
        {
          name = "OBJECT_STORAGE_ACCESS_KEY"
          valueFrom = {
            secretKeyRef = {
              name = "btp-secrets"
              key = "minio-access-key"
            }
          }
        },
        {
          name = "OBJECT_STORAGE_SECRET_KEY"
          valueFrom = {
            secretKeyRef = {
              name = "btp-secrets"
              key = "minio-secret-key"
            }
          }
        },
        {
          name = "OAUTH_ISSUER"
          value = module.oauth.issuer_url
        },
        {
          name = "OAUTH_CLIENT_ID"
          value = module.oauth.client_id
        },
        {
          name = "OAUTH_CLIENT_SECRET"
          valueFrom = {
            secretKeyRef = {
              name = "btp-secrets"
              key = "oauth-client-secret"
            }
          }
        },
        {
          name = "VAULT_ENDPOINT"
          value = module.secrets.endpoint
        },
        {
          name = "VAULT_TOKEN"
          valueFrom = {
            secretKeyRef = {
              name = "btp-secrets"
              key = "vault-token"
            }
          }
        },
        {
          name = "JWT_SIGNING_KEY"
          valueFrom = {
            secretKeyRef = {
              name = "btp-secrets"
              key = "jwt-signing-key"
            }
          }
        }
      ]
    })
  ]
  
  depends_on = [
    module.postgres,
    module.redis,
    module.object_storage,
    module.oauth,
    module.secrets,
    module.ingress_tls,
    module.metrics_logs
  ]
}
```

## Helm Charts

### Chart Dependencies

#### Chart.yaml
```yaml
apiVersion: v2
name: btp-platform
description: SettleMint BTP Platform
type: application
version: 1.0.0
appVersion: "1.0.0"

dependencies:
- name: postgresql
  version: "12.1.9"
  repository: "https://charts.bitnami.com/bitnami"
  condition: postgresql.enabled
  
- name: redis
  version: "17.3.7"
  repository: "https://charts.bitnami.com/bitnami"
  condition: redis.enabled
  
- name: minio
  version: "12.7.4"
  repository: "https://charts.bitnami.com/bitnami"
  condition: minio.enabled
  
- name: vault
  version: "0.26.0"
  repository: "https://helm.releases.hashicorp.com"
  condition: vault.enabled
  
- name: keycloak
  version: "23.0.0"
  repository: "https://charts.bitnami.com/bitnami"
  condition: keycloak.enabled
  
- name: kube-prometheus-stack
  version: "51.4.0"
  repository: "https://prometheus-community.github.io/helm-charts"
  condition: prometheus.enabled
  
- name: grafana
  version: "7.0.12"
  repository: "https://grafana.github.io/helm-charts"
  condition: grafana.enabled
  
- name: loki
  version: "5.45.0"
  repository: "https://grafana.github.io/helm-charts"
  condition: loki.enabled
```

### Chart Values

#### values.yaml
```yaml
# Global configuration
global:
  imageRegistry: ""
  imagePullSecrets: []
  storageClass: ""

# BTP Platform configuration
btpPlatform:
  enabled: true
  
  image:
    repository: settlemint/btp-platform
    tag: latest
    pullPolicy: IfNotPresent
  
  replicaCount: 1
  
  service:
    type: ClusterIP
    port: 8080
  
  ingress:
    enabled: true
    className: "nginx"
    annotations: {}
    hosts:
      - host: btp.example.com
        paths:
          - path: /
            pathType: Prefix
    tls: []
  
  resources:
    limits:
      cpu: 1000m
      memory: 1Gi
    requests:
      cpu: 500m
      memory: 512Mi
  
  nodeSelector: {}
  tolerations: []
  affinity: {}
  
  env: []
  envFrom: []
  
  volumeMounts: []
  volumes: []

# PostgreSQL configuration
postgresql:
  enabled: true
  auth:
    postgresPassword: ""
    username: "btp_user"
    password: ""
    database: "btp"
  
  primary:
    persistence:
      enabled: true
      size: 8Gi
      storageClass: ""
  
  metrics:
    enabled: true

# Redis configuration
redis:
  enabled: true
  auth:
    enabled: true
    password: ""
  
  master:
    persistence:
      enabled: true
      size: 8Gi
      storageClass: ""
  
  metrics:
    enabled: true

# MinIO configuration
minio:
  enabled: true
  auth:
    rootUser: "minioadmin"
    rootPassword: ""
  
  defaultBuckets: "btp-artifacts"
  
  persistence:
    enabled: true
    size: 50Gi
    storageClass: ""
  
  metrics:
    enabled: true

# Vault configuration
vault:
  enabled: true
  
  server:
    ha:
      enabled: true
      replicas: 3
  
  ui:
    enabled: true

# Keycloak configuration
keycloak:
  enabled: true
  
  auth:
    adminUser: "admin"
    adminPassword: ""
  
  postgresql:
    auth:
      username: "keycloak"
      password: ""
      database: "keycloak"
  
  metrics:
    enabled: true

# Prometheus configuration
prometheus:
  enabled: true
  
  prometheus:
    prometheusSpec:
      retention: 30d
      storageSpec:
        volumeClaimTemplate:
          spec:
            storageClassName: ""
            accessModes: ["ReadWriteOnce"]
            resources:
              requests:
                storage: 50Gi

# Grafana configuration
grafana:
  enabled: true
  
  adminPassword: ""
  
  persistence:
    enabled: true
    size: 10Gi
    storageClass: ""
  
  dashboards:
    default:
      btp-overview:
        gnetId: 1860
        revision: 1
        datasource: Prometheus

# Loki configuration
loki:
  enabled: true
  
  persistence:
    enabled: true
    size: 100Gi
    storageClass: ""
```

## Environment Variables

### Required Environment Variables

#### License Configuration
```bash
# License information
LICENSE_USERNAME="your-license-username"
LICENSE_PASSWORD="your-license-password"
LICENSE_SIGNATURE="your-license-signature"
LICENSE_EMAIL="your-license-email"
LICENSE_EXPIRATION_DATE="2024-12-31"
```

#### Security Secrets
```bash
# Platform security
JWT_SIGNING_KEY="your-jwt-signing-key"
IPFS_CLUSTER_SECRET="your-ipfs-cluster-secret"
STATE_ENCRYPTION_KEY="your-state-encryption-key"

# Cloud credentials
AWS_ACCESS_KEY_ID="your-aws-access-key-id"
AWS_SECRET_ACCESS_KEY="your-aws-secret-access-key"
GOOGLE_OAUTH_CLIENT_ID="your-google-oauth-client-id"
GOOGLE_OAUTH_CLIENT_SECRET="your-google-oauth-client-secret"

# Admin passwords
GRAFANA_ADMIN_PASSWORD="your-grafana-admin-password"
POSTGRES_PASSWORD="your-postgres-password"
REDIS_PASSWORD="your-redis-password"
OBJECT_STORAGE_ACCESS_KEY="your-object-storage-access-key"
OBJECT_STORAGE_SECRET_KEY="your-object-storage-secret-key"
OAUTH_ADMIN_PASSWORD="your-oauth-admin-password"
```

### Optional Environment Variables

#### Platform Configuration
```bash
# Platform settings
PLATFORM="aws"
BASE_DOMAIN="btp.example.com"
ENVIRONMENT="production"
REGION="us-east-1"

# Cluster configuration
CLUSTER_NAME="btp-cluster"
NODE_GROUP_NAME="btp-nodes"
INSTANCE_TYPE="t3.medium"
MIN_SIZE="1"
MAX_SIZE="5"
DESIRED_SIZE="2"

# Namespace configuration
SETTLEMINT_NAMESPACE="settlemint"
BTP_DEPS_NAMESPACE="btp-deps"
```

#### Monitoring Configuration
```bash
# Monitoring settings
PROMETHEUS_RETENTION="30d"
GRAFANA_ADMIN_USER="admin"
LOKI_RETENTION="30d"

# Alerting
ALERT_EMAIL="admin@btp.example.com"
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
```

## Next Steps

- [Examples](23-examples.md) - Configuration examples
- [FAQ](24-faq.md) - Frequently asked questions
- [Contributing](25-contributing.md) - Contributing guidelines

---

*This API Reference provides comprehensive documentation for all variables, outputs, modules, and configuration options available in the SettleMint BTP Universal Terraform project. Use this reference to understand the complete API surface and customize your deployment.*
