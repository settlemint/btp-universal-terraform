# Examples

## Overview

This document provides comprehensive examples for deploying the SettleMint BTP platform using the Universal Terraform project. It includes real-world scenarios, use cases, and complete configuration examples.

## Table of Contents

- [Basic Examples](#basic-examples)
- [Production Examples](#production-examples)
- [Multi-Environment Examples](#multi-environment-examples)
- [Custom Configuration Examples](#custom-configuration-examples)
- [Troubleshooting Examples](#troubleshooting-examples)
- [Integration Examples](#integration-examples)

## Basic Examples

### Minimal Kubernetes Deployment

#### Configuration
```hcl
# examples/minimal-k8s.tfvars
platform = "generic"
base_domain = "btp.local"
environment = "dev"

# Use existing Kubernetes cluster
cluster = {
  create = false
  name   = "existing-cluster"
  region = "us-east-1"
}

# Minimal BTP platform
btp = {
  enabled = true
  values = {
    resources = {
      requests = {
        memory = "256Mi"
        cpu    = "250m"
      }
      limits = {
        memory = "512Mi"
        cpu    = "500m"
      }
    }
  }
}

# All dependencies in Kubernetes mode
postgres = {
  mode = "k8s"
  k8s = {
    chart_version = "12.1.9"
    release_name  = "postgres"
    password      = "postgres123"
    persistence = {
      enabled = true
      size    = "8Gi"
    }
  }
}

redis = {
  mode = "k8s"
  k8s = {
    chart_version = "17.3.7"
    release_name  = "redis"
    password      = "redis123"
    persistence = {
      enabled = true
      size    = "4Gi"
    }
  }
}

object_storage = {
  mode = "k8s"
  k8s = {
    chart_version = "12.7.4"
    release_name  = "minio"
    access_key    = "minioadmin"
    secret_key    = "minioadmin123456789012"
    persistence = {
      enabled = true
      size    = "20Gi"
    }
  }
}

oauth = {
  mode = "k8s"
  k8s = {
    chart_version  = "23.0.0"
    release_name   = "keycloak"
    admin_username = "admin"
    admin_password = "admin123"
    database = {
      type     = "postgresql"
      host     = "postgres.btp-deps.svc.cluster.local"
      port     = 5432
      database = "keycloak"
      username = "keycloak"
      password = "keycloak123"
    }
  }
}

secrets = {
  mode = "k8s"
  k8s = {
    chart_version = "0.26.0"
    release_name  = "vault"
    ha = {
      enabled  = true
      replicas = 1
    }
  }
}

metrics_logs = {
  mode = "k8s"
  k8s = {
    prometheus = {
      chart_version = "51.4.0"
      release_name  = "prometheus"
      persistence = {
        enabled = true
        size    = "20Gi"
      }
    }
    grafana = {
      chart_version = "7.0.12"
      release_name  = "grafana"
      admin_user    = "admin"
      admin_password = "admin123"
      persistence = {
        enabled = true
        size    = "4Gi"
      }
    }
    loki = {
      chart_version = "5.45.0"
      release_name  = "loki"
      persistence = {
        enabled = true
        size    = "20Gi"
      }
    }
  }
}
```

#### Deployment Commands
```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file=examples/minimal-k8s.tfvars

# Apply deployment
terraform apply -var-file=examples/minimal-k8s.tfvars

# Verify deployment
kubectl get pods -A
kubectl get svc -A
kubectl get ingress -A
```

### Development Environment

#### Configuration
```hcl
# examples/dev-environment.tfvars
platform = "aws"
base_domain = "dev.btp.example.com"
environment = "dev"

# Small AWS cluster
cluster = {
  create = true
  name   = "btp-dev-cluster"
  region = "us-east-1"
  node_groups = {
    main = {
      instance_types = ["t3.small"]
      min_size      = 1
      max_size      = 3
      desired_size  = 2
      disk_size     = 20
      disk_type     = "gp3"
    }
  }
}

# Development BTP platform
btp = {
  enabled = true
  values = {
    resources = {
      requests = {
        memory = "512Mi"
        cpu    = "500m"
      }
      limits = {
        memory = "1Gi"
        cpu    = "1000m"
      }
    }
    env = [
      {
        name  = "LOG_LEVEL"
        value = "debug"
      },
      {
        name  = "ENVIRONMENT"
        value = "development"
      }
    ]
  }
}

# Mixed deployment modes
postgres = {
  mode = "aws"
  aws = {
    cluster_id                 = "btp-dev-postgres"
    engine_version             = "15.4"
    node_type                  = "db.t3.micro"
    num_cache_nodes            = 1
    multi_az                   = false
    backup_retention_period    = 7
    performance_insights_enabled = false
  }
}

redis = {
  mode = "k8s"
  k8s = {
    chart_version = "17.3.7"
    release_name  = "redis"
    password      = "redis123"
    persistence = {
      enabled = true
      size    = "4Gi"
    }
  }
}

object_storage = {
  mode = "aws"
  aws = {
    bucket_name        = "btp-dev-artifacts"
    region             = "us-east-1"
    versioning_enabled = true
  }
}

oauth = {
  mode = "k8s"
  k8s = {
    chart_version  = "23.0.0"
    release_name   = "keycloak"
    admin_username = "admin"
    admin_password = "admin123"
    database = {
      type     = "postgresql"
      host     = "btp-dev-postgres.cluster-xyz.us-east-1.rds.amazonaws.com"
      port     = 5432
      database = "keycloak"
      username = "keycloak"
      password = "keycloak123"
    }
  }
}

secrets = {
  mode = "aws"
  aws = {
    region = "us-east-1"
    secrets = [
      {
        name = "btp-dev-postgres-password"
        description = "PostgreSQL password for BTP dev environment"
        secret_string = jsonencode({
          username = "btp_user"
          password = "postgres123"
        })
      }
    ]
  }
}

metrics_logs = {
  mode = "k8s"
  k8s = {
    prometheus = {
      chart_version = "51.4.0"
      release_name  = "prometheus"
      persistence = {
        enabled = true
        size    = "10Gi"
      }
    }
    grafana = {
      chart_version = "7.0.12"
      release_name  = "grafana"
      admin_user    = "admin"
      admin_password = "admin123"
      persistence = {
        enabled = true
        size    = "2Gi"
      }
    }
  }
}
```

## Production Examples

### High-Availability AWS Deployment

#### Configuration
```hcl
# examples/production-aws.tfvars
platform = "aws"
base_domain = "btp.example.com"
environment = "production"

# High-availability AWS cluster
cluster = {
  create = true
  name   = "btp-prod-cluster"
  region = "us-east-1"
  node_groups = {
    main = {
      instance_types = ["t3.large"]
      min_size      = 3
      max_size      = 10
      desired_size  = 5
      disk_size     = 100
      disk_type     = "gp3"
    }
    spot = {
      instance_types = ["t3.large", "t3.xlarge"]
      min_size      = 0
      max_size      = 5
      desired_size  = 2
      disk_size     = 100
      disk_type     = "gp3"
    }
  }
  addons = {
    aws_load_balancer_controller = true
    aws_ebs_csi_driver          = true
    aws_efs_csi_driver          = true
    aws_cloudwatch_observability = true
  }
}

# Production BTP platform
btp = {
  enabled = true
  values = {
    resources = {
      requests = {
        memory = "1Gi"
        cpu    = "1000m"
      }
      limits = {
        memory = "2Gi"
        cpu    = "2000m"
      }
    }
    autoscaling = {
      enabled = true
      minReplicas = 3
      maxReplicas = 20
      targetCPUUtilizationPercentage = 60
      targetMemoryUtilizationPercentage = 70
    }
    env = [
      {
        name  = "LOG_LEVEL"
        value = "info"
      },
      {
        name  = "ENVIRONMENT"
        value = "production"
      },
      {
        name  = "METRICS_ENABLED"
        value = "true"
      }
    ]
  }
}

# All AWS managed services
postgres = {
  mode = "aws"
  aws = {
    cluster_id                 = "btp-prod-postgres"
    engine_version             = "15.4"
    node_type                  = "db.r5.large"
    num_cache_nodes            = 1
    multi_az                   = true
    automatic_failover_enabled = true
    backup_retention_period    = 30
    performance_insights_enabled = true
    monitoring_interval        = 60
    subnet_ids = [
      "subnet-12345",
      "subnet-67890"
    ]
    security_group_ids = [
      "sg-12345"
    ]
  }
}

redis = {
  mode = "aws"
  aws = {
    cluster_id                 = "btp-prod-redis"
    engine_version             = "7.0"
    node_type                  = "cache.r5.large"
    num_cache_nodes            = 1
    multi_az                   = true
    automatic_failover_enabled = true
    auth_token                 = "secure-redis-token"
    transit_encryption_enabled = true
    at_rest_encryption_enabled = true
    subnet_ids = [
      "subnet-12345",
      "subnet-67890"
    ]
    security_group_ids = [
      "sg-12345"
    ]
    snapshot_retention_limit = 5
    snapshot_window         = "03:00-05:00"
    maintenance_window      = "sun:05:00-sun:09:00"
  }
}

object_storage = {
  mode = "aws"
  aws = {
    bucket_name        = "btp-prod-artifacts"
    region             = "us-east-1"
    versioning_enabled = true
    server_side_encryption_configuration = {
      rule = {
        apply_server_side_encryption_by_default = {
          sse_algorithm = "AES256"
        }
      }
    }
    public_access_block_configuration = {
      block_public_acls       = true
      block_public_policy     = true
      ignore_public_acls      = true
      restrict_public_buckets = true
    }
    lifecycle_rule = [
      {
        id     = "transition_to_ia"
        status = "Enabled"
        transition = [
          {
            days          = 30
            storage_class = "STANDARD_IA"
          }
        ]
        expiration = {
          days = 365
        }
      }
    ]
  }
}

oauth = {
  mode = "aws"
  aws = {
    user_pool_name = "btp-prod-users"
    region         = "us-east-1"
    username_attributes = ["email"]
    auto_verified_attributes = ["email"]
    mfa_configuration = "OPTIONAL"
    password_policy = {
      minimum_length    = 8
      require_lowercase = true
      require_uppercase = true
      require_numbers   = true
      require_symbols   = true
    }
    client_name = "btp-prod-client"
    client_settings = {
      generate_secret = true
      explicit_auth_flows = [
        "ALLOW_USER_PASSWORD_AUTH",
        "ALLOW_USER_SRP_AUTH",
        "ALLOW_REFRESH_TOKEN_AUTH"
      ]
      supported_identity_providers = ["COGNITO"]
      callback_urls = [
        "https://btp.example.com/auth/callback"
      ]
      logout_urls = [
        "https://btp.example.com/auth/logout"
      ]
    }
    domain = "auth.btp.example.com"
    identity_providers = [
      {
        provider_name = "Google"
        provider_type = "Google"
        provider_details = {
          client_id     = "your-google-client-id"
          client_secret = "your-google-client-secret"
          authorize_scopes = "email openid profile"
        }
        attribute_mapping = {
          email = "email"
          username = "sub"
        }
      }
    ]
  }
}

secrets = {
  mode = "aws"
  aws = {
    region = "us-east-1"
    secrets = [
      {
        name = "btp-prod-postgres-password"
        description = "PostgreSQL password for BTP production environment"
        secret_string = jsonencode({
          username = "btp_user"
          password = "secure-postgres-password"
          engine = "postgres"
          host = "btp-prod-postgres.cluster-xyz.us-east-1.rds.amazonaws.com"
          port = 5432
          dbname = "btp"
        })
        rotation_config = {
          enabled = true
          rotation_lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:rotate-postgres-password"
          rotation_days = 30
        }
      },
      {
        name = "btp-prod-redis-password"
        description = "Redis password for BTP production environment"
        secret_string = jsonencode({
          password = "secure-redis-password"
          host = "btp-prod-redis.xyz.cache.amazonaws.com"
          port = 6379
        })
      }
    ]
    kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  }
}

metrics_logs = {
  mode = "aws"
  aws = {
    region = "us-east-1"
    log_groups = [
      {
        name = "/aws/eks/btp-prod-cluster/application"
        retention_in_days = 30
        kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
      },
      {
        name = "/aws/eks/btp-prod-cluster/audit"
        retention_in_days = 90
        kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
      }
    ]
    alarms = [
      {
        name = "btp-prod-cpu-high"
        comparison_operator = "GreaterThanThreshold"
        evaluation_periods = "2"
        metric_name = "CPUUtilization"
        namespace = "AWS/EKS"
        period = "300"
        statistic = "Average"
        threshold = "80"
        alarm_description = "This metric monitors EKS cluster CPU utilization"
        alarm_actions = ["arn:aws:sns:us-east-1:123456789012:btp-prod-alerts"]
      }
    ]
    dashboards = [
      {
        name = "btp-prod-overview"
        dashboard_body = jsonencode({
          widgets = [
            {
              type = "metric"
              x = 0
              y = 0
              width = 12
              height = 6
              properties = {
                metrics = [
                  ["AWS/EKS", "CPUUtilization", "ClusterName", "btp-prod-cluster"],
                  [".", "MemoryUtilization", ".", "."]
                ]
                view = "timeSeries"
                stacked = false
                region = "us-east-1"
                title = "EKS Cluster Metrics"
                period = 300
              }
            }
          ]
        })
      }
    ]
  }
}
```

### Multi-Region Azure Deployment

#### Configuration
```hcl
# examples/production-azure.tfvars
platform = "azure"
base_domain = "btp.example.com"
environment = "production"

# Multi-region Azure cluster
cluster = {
  create = true
  name   = "btp-prod-cluster"
  region = "East US"
  node_groups = {
    main = {
      instance_types = ["Standard_D2s_v3"]
      min_size      = 3
      max_size      = 10
      desired_size  = 5
      disk_size     = 100
      disk_type     = "Premium_LRS"
    }
  }
}

# Production BTP platform
btp = {
  enabled = true
  values = {
    resources = {
      requests = {
        memory = "1Gi"
        cpu    = "1000m"
      }
      limits = {
        memory = "2Gi"
        cpu    = "2000m"
      }
    }
    autoscaling = {
      enabled = true
      minReplicas = 3
      maxReplicas = 20
      targetCPUUtilizationPercentage = 60
      targetMemoryUtilizationPercentage = 70
    }
  }
}

# All Azure managed services
postgres = {
  mode = "azure"
  azure = {
    cache_name          = "btp-prod-postgres"
    location            = "East US"
    resource_group_name = "btp-prod-resources"
    capacity            = 1
    family              = "Gen5"
    sku_name            = "GP_Gen5_2"
    enable_non_ssl_port = false
    minimum_tls_version = "1.2"
    redis_configuration = {
      maxmemory_reserved = "2"
      maxmemory_delta    = "2"
      maxmemory_policy   = "allkeys-lru"
    }
    subnet_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/.../subnets/..."
    enable_backup = true
    backup_frequency = 15
    backup_max_count = 1
  }
}

redis = {
  mode = "azure"
  azure = {
    cache_name          = "btp-prod-redis"
    location            = "East US"
    resource_group_name = "btp-prod-resources"
    capacity            = 1
    family              = "C"
    sku_name            = "Standard"
    enable_non_ssl_port = false
    minimum_tls_version = "1.2"
    redis_configuration = {
      maxmemory_reserved = "2"
      maxmemory_delta    = "2"
      maxmemory_policy   = "allkeys-lru"
    }
    subnet_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/.../subnets/..."
    enable_backup = true
    backup_frequency = 15
    backup_max_count = 1
  }
}

object_storage = {
  mode = "azure"
  azure = {
    storage_account_name = "btpprodstorage"
    resource_group_name  = "btp-prod-resources"
    location             = "East US"
    account_tier         = "Standard"
    replication_type     = "LRS"
    container_name       = "btp-artifacts"
    container_access_type = "private"
    allow_nested_items_to_be_public = false
    shared_access_key_enabled = true
    account_kind         = "StorageV2"
    access_tier          = "Hot"
    network_rules = {
      default_action = "Deny"
      virtual_network_subnet_ids = ["/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/.../subnets/..."]
      ip_rules = ["1.2.3.4"]
    }
    lifecycle_rule = [
      {
        name    = "archive_old_data"
        enabled = true
        expiration = {
          days = 365
        }
        transition = [
          {
            days          = 30
            storage_class = "COOL"
          },
          {
            days          = 90
            storage_class = "ARCHIVE"
          }
        ]
      }
    ]
  }
}

oauth = {
  mode = "azure"
  azure = {
    tenant_name = "btp-prod-tenant"
    location    = "East US"
    sku_name    = "PremiumP1"
    user_flows = [
      {
        name = "B2C_1_signup_signin"
        type = "signUpOrSignIn"
        user_flow_type = "signUpOrSignIn"
        identity_providers = [
          {
            name = "Google"
            type = "Google"
            client_id = "your-google-client-id"
            client_secret = "your-google-client-secret"
          }
        ]
        user_attributes = [
          "displayName",
          "givenName",
          "surname",
          "email"
        ]
        application_claims = [
          "displayName",
          "givenName",
          "surname",
          "email"
        ]
      }
    ]
    application_registration = {
      display_name = "BTP Production Application"
      sign_in_audience = "AzureADandPersonalMicrosoftAccount"
      redirect_uris = [
        "https://btp.example.com/auth/callback"
      ]
      api_permissions = [
        "openid",
        "profile",
        "email"
      ]
    }
    custom_domain = "auth.btp.example.com"
  }
}

secrets = {
  mode = "azure"
  azure = {
    key_vault_name = "btp-prod-keyvault"
    resource_group_name = "btp-prod-resources"
    location = "East US"
    sku_name = "standard"
    access_policies = [
      {
        tenant_id = "your-tenant-id"
        object_id = "your-object-id"
        key_permissions = ["Get", "List", "Create", "Delete", "Update"]
        secret_permissions = ["Get", "List", "Set", "Delete"]
        certificate_permissions = ["Get", "List", "Create", "Delete", "Update"]
      }
    ]
    network_acls = {
      default_action = "Deny"
      bypass = "AzureServices"
      virtual_network_subnet_ids = ["/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/.../subnets/..."]
      ip_rules = ["1.2.3.4"]
    }
    soft_delete_retention_days = 90
    purge_protection_enabled = true
    secrets = [
      {
        name = "btp-prod-postgres-password"
        value = "secure-postgres-password"
        content_type = "password"
        tags = {
          Environment = "production"
          Application = "btp"
        }
      }
    ]
  }
}

metrics_logs = {
  mode = "azure"
  azure = {
    resource_group_name = "btp-prod-resources"
    location = "East US"
    log_analytics_workspace = {
      name = "btp-prod-logs"
      sku = "PerGB2018"
      retention_in_days = 30
    }
    application_insights = {
      name = "btp-prod-insights"
      application_type = "web"
      daily_data_cap_in_gb = 1
      daily_data_cap_notifications_disabled = false
      retention_in_days = 30
      sampling_percentage = 100
      disable_ip_masking = false
    }
    alerts = [
      {
        name = "btp-prod-cpu-high"
        description = "Alert when CPU usage is high"
        severity = 2
        frequency = "PT5M"
        window_size = "PT5M"
        criteria = {
          metric_name = "Percentage CPU"
          metric_namespace = "Microsoft.Compute/virtualMachines"
          operator = "GreaterThan"
          threshold = 80
          aggregation = "Average"
        }
        action_group_name = "btp-prod-alerts"
      }
    ]
  }
}
```

## Multi-Environment Examples

### Development, Staging, and Production

#### Development Environment
```hcl
# examples/dev.tfvars
platform = "aws"
base_domain = "dev.btp.example.com"
environment = "dev"

cluster = {
  create = true
  name   = "btp-dev-cluster"
  region = "us-east-1"
  node_groups = {
    main = {
      instance_types = ["t3.small"]
      min_size      = 1
      max_size      = 3
      desired_size  = 2
      disk_size     = 20
      disk_type     = "gp3"
    }
  }
}

btp = {
  enabled = true
  values = {
    resources = {
      requests = {
        memory = "512Mi"
        cpu    = "500m"
      }
      limits = {
        memory = "1Gi"
        cpu    = "1000m"
      }
    }
    env = [
      {
        name  = "LOG_LEVEL"
        value = "debug"
      },
      {
        name  = "ENVIRONMENT"
        value = "development"
      }
    ]
  }
}

# Use managed services for dev
postgres = {
  mode = "aws"
  aws = {
    cluster_id                 = "btp-dev-postgres"
    engine_version             = "15.4"
    node_type                  = "db.t3.micro"
    num_cache_nodes            = 1
    multi_az                   = false
    backup_retention_period    = 7
  }
}

redis = {
  mode = "aws"
  aws = {
    cluster_id                 = "btp-dev-redis"
    engine_version             = "7.0"
    node_type                  = "cache.t3.micro"
    num_cache_nodes            = 1
    multi_az                   = false
  }
}

object_storage = {
  mode = "aws"
  aws = {
    bucket_name        = "btp-dev-artifacts"
    region             = "us-east-1"
    versioning_enabled = false
  }
}

oauth = {
  mode = "k8s"
  k8s = {
    chart_version  = "23.0.0"
    release_name   = "keycloak"
    admin_username = "admin"
    admin_password = "admin123"
  }
}

secrets = {
  mode = "k8s"
  k8s = {
    chart_version = "0.26.0"
    release_name  = "vault"
    ha = {
      enabled  = true
      replicas = 1
    }
  }
}

metrics_logs = {
  mode = "k8s"
  k8s = {
    prometheus = {
      chart_version = "51.4.0"
      release_name  = "prometheus"
      persistence = {
        enabled = true
        size    = "10Gi"
      }
    }
    grafana = {
      chart_version = "7.0.12"
      release_name  = "grafana"
      admin_user    = "admin"
      admin_password = "admin123"
      persistence = {
        enabled = true
        size    = "2Gi"
      }
    }
  }
}
```

#### Staging Environment
```hcl
# examples/staging.tfvars
platform = "aws"
base_domain = "staging.btp.example.com"
environment = "staging"

cluster = {
  create = true
  name   = "btp-staging-cluster"
  region = "us-east-1"
  node_groups = {
    main = {
      instance_types = ["t3.medium"]
      min_size      = 2
      max_size      = 5
      desired_size  = 3
      disk_size     = 50
      disk_type     = "gp3"
    }
  }
}

btp = {
  enabled = true
  values = {
    resources = {
      requests = {
        memory = "1Gi"
        cpu    = "1000m"
      }
      limits = {
        memory = "2Gi"
        cpu    = "2000m"
      }
    }
    autoscaling = {
      enabled = true
      minReplicas = 2
      maxReplicas = 10
      targetCPUUtilizationPercentage = 70
      targetMemoryUtilizationPercentage = 80
    }
    env = [
      {
        name  = "LOG_LEVEL"
        value = "info"
      },
      {
        name  = "ENVIRONMENT"
        value = "staging"
      }
    ]
  }
}

# Use managed services for staging
postgres = {
  mode = "aws"
  aws = {
    cluster_id                 = "btp-staging-postgres"
    engine_version             = "15.4"
    node_type                  = "db.t3.small"
    num_cache_nodes            = 1
    multi_az                   = true
    backup_retention_period    = 14
  }
}

redis = {
  mode = "aws"
  aws = {
    cluster_id                 = "btp-staging-redis"
    engine_version             = "7.0"
    node_type                  = "cache.t3.small"
    num_cache_nodes            = 1
    multi_az                   = true
  }
}

object_storage = {
  mode = "aws"
  aws = {
    bucket_name        = "btp-staging-artifacts"
    region             = "us-east-1"
    versioning_enabled = true
  }
}

oauth = {
  mode = "aws"
  aws = {
    user_pool_name = "btp-staging-users"
    region         = "us-east-1"
    username_attributes = ["email"]
    auto_verified_attributes = ["email"]
    mfa_configuration = "OPTIONAL"
    client_name = "btp-staging-client"
    client_settings = {
      generate_secret = true
      explicit_auth_flows = [
        "ALLOW_USER_PASSWORD_AUTH",
        "ALLOW_USER_SRP_AUTH",
        "ALLOW_REFRESH_TOKEN_AUTH"
      ]
      supported_identity_providers = ["COGNITO"]
      callback_urls = [
        "https://staging.btp.example.com/auth/callback"
      ]
      logout_urls = [
        "https://staging.btp.example.com/auth/logout"
      ]
    }
  }
}

secrets = {
  mode = "aws"
  aws = {
    region = "us-east-1"
    secrets = [
      {
        name = "btp-staging-postgres-password"
        description = "PostgreSQL password for BTP staging environment"
        secret_string = jsonencode({
          username = "btp_user"
          password = "staging-postgres-password"
        })
      }
    ]
  }
}

metrics_logs = {
  mode = "aws"
  aws = {
    region = "us-east-1"
    log_groups = [
      {
        name = "/aws/eks/btp-staging-cluster/application"
        retention_in_days = 14
      }
    ]
  }
}
```

#### Production Environment
```hcl
# examples/production.tfvars
platform = "aws"
base_domain = "btp.example.com"
environment = "production"

cluster = {
  create = true
  name   = "btp-prod-cluster"
  region = "us-east-1"
  node_groups = {
    main = {
      instance_types = ["t3.large"]
      min_size      = 3
      max_size      = 10
      desired_size  = 5
      disk_size     = 100
      disk_type     = "gp3"
    }
    spot = {
      instance_types = ["t3.large", "t3.xlarge"]
      min_size      = 0
      max_size      = 5
      desired_size  = 2
      disk_size     = 100
      disk_type     = "gp3"
    }
  }
  addons = {
    aws_load_balancer_controller = true
    aws_ebs_csi_driver          = true
    aws_efs_csi_driver          = true
    aws_cloudwatch_observability = true
  }
}

btp = {
  enabled = true
  values = {
    resources = {
      requests = {
        memory = "1Gi"
        cpu    = "1000m"
      }
      limits = {
        memory = "2Gi"
        cpu    = "2000m"
      }
    }
    autoscaling = {
      enabled = true
      minReplicas = 3
      maxReplicas = 20
      targetCPUUtilizationPercentage = 60
      targetMemoryUtilizationPercentage = 70
    }
    env = [
      {
        name  = "LOG_LEVEL"
        value = "info"
      },
      {
        name  = "ENVIRONMENT"
        value = "production"
      },
      {
        name  = "METRICS_ENABLED"
        value = "true"
      }
    ]
  }
}

# All managed services for production
postgres = {
  mode = "aws"
  aws = {
    cluster_id                 = "btp-prod-postgres"
    engine_version             = "15.4"
    node_type                  = "db.r5.large"
    num_cache_nodes            = 1
    multi_az                   = true
    automatic_failover_enabled = true
    backup_retention_period    = 30
    performance_insights_enabled = true
    monitoring_interval        = 60
  }
}

redis = {
  mode = "aws"
  aws = {
    cluster_id                 = "btp-prod-redis"
    engine_version             = "7.0"
    node_type                  = "cache.r5.large"
    num_cache_nodes            = 1
    multi_az                   = true
    automatic_failover_enabled = true
    auth_token                 = "secure-redis-token"
    transit_encryption_enabled = true
    at_rest_encryption_enabled = true
  }
}

object_storage = {
  mode = "aws"
  aws = {
    bucket_name        = "btp-prod-artifacts"
    region             = "us-east-1"
    versioning_enabled = true
    server_side_encryption_configuration = {
      rule = {
        apply_server_side_encryption_by_default = {
          sse_algorithm = "AES256"
        }
      }
    }
    public_access_block_configuration = {
      block_public_acls       = true
      block_public_policy     = true
      ignore_public_acls      = true
      restrict_public_buckets = true
    }
  }
}

oauth = {
  mode = "aws"
  aws = {
    user_pool_name = "btp-prod-users"
    region         = "us-east-1"
    username_attributes = ["email"]
    auto_verified_attributes = ["email"]
    mfa_configuration = "OPTIONAL"
    password_policy = {
      minimum_length    = 8
      require_lowercase = true
      require_uppercase = true
      require_numbers   = true
      require_symbols   = true
    }
    client_name = "btp-prod-client"
    client_settings = {
      generate_secret = true
      explicit_auth_flows = [
        "ALLOW_USER_PASSWORD_AUTH",
        "ALLOW_USER_SRP_AUTH",
        "ALLOW_REFRESH_TOKEN_AUTH"
      ]
      supported_identity_providers = ["COGNITO"]
      callback_urls = [
        "https://btp.example.com/auth/callback"
      ]
      logout_urls = [
        "https://btp.example.com/auth/logout"
      ]
    }
    domain = "auth.btp.example.com"
  }
}

secrets = {
  mode = "aws"
  aws = {
    region = "us-east-1"
    secrets = [
      {
        name = "btp-prod-postgres-password"
        description = "PostgreSQL password for BTP production environment"
        secret_string = jsonencode({
          username = "btp_user"
          password = "secure-postgres-password"
        })
        rotation_config = {
          enabled = true
          rotation_lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:rotate-postgres-password"
          rotation_days = 30
        }
      }
    ]
    kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  }
}

metrics_logs = {
  mode = "aws"
  aws = {
    region = "us-east-1"
    log_groups = [
      {
        name = "/aws/eks/btp-prod-cluster/application"
        retention_in_days = 30
        kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
      },
      {
        name = "/aws/eks/btp-prod-cluster/audit"
        retention_in_days = 90
        kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
      }
    ]
    alarms = [
      {
        name = "btp-prod-cpu-high"
        comparison_operator = "GreaterThanThreshold"
        evaluation_periods = "2"
        metric_name = "CPUUtilization"
        namespace = "AWS/EKS"
        period = "300"
        statistic = "Average"
        threshold = "80"
        alarm_description = "This metric monitors EKS cluster CPU utilization"
        alarm_actions = ["arn:aws:sns:us-east-1:123456789012:btp-prod-alerts"]
      }
    ]
  }
}
```

## Custom Configuration Examples

### Custom BTP Platform Configuration

#### Advanced BTP Configuration
```hcl
# examples/custom-btp.tfvars
platform = "aws"
base_domain = "btp.example.com"
environment = "production"

btp = {
  enabled = true
  values = {
    # Application configuration
    app = {
      name = "btp-platform"
      version = "latest"
      environment = "production"
    }
    
    # Resource configuration
    resources = {
      requests = {
        memory = "1Gi"
        cpu = "1000m"
      }
      limits = {
        memory = "2Gi"
        cpu = "2000m"
      }
    }
    
    # Autoscaling
    autoscaling = {
      enabled = true
      minReplicas = 3
      maxReplicas = 20
      targetCPUUtilizationPercentage = 60
      targetMemoryUtilizationPercentage = 70
    }
    
    # Environment variables
    env = [
      {
        name = "LOG_LEVEL"
        value = "info"
      },
      {
        name = "METRICS_ENABLED"
        value = "true"
      },
      {
        name = "HEALTH_CHECK_ENABLED"
        value = "true"
      },
      {
        name = "CORS_ENABLED"
        value = "true"
      },
      {
        name = "CORS_ALLOWED_ORIGINS"
        value = "https://btp.example.com,https://app.btp.example.com"
      }
    ]
    
    # Database configuration
    database = {
      host = "postgres.btp-deps.svc.cluster.local"
      port = 5432
      name = "btp"
      username = "btp_user"
      password = "${POSTGRES_PASSWORD}"
      sslMode = "require"
      maxConnections = 100
      connectionTimeout = 30
      idleTimeout = 600
      maxLifetime = 3600
    }
    
    # Redis configuration
    redis = {
      host = "redis.btp-deps.svc.cluster.local"
      port = 6379
      password = "${REDIS_PASSWORD}"
      db = 0
      maxRetries = 3
      poolSize = 10
      minIdleConns = 5
      maxConnAge = 3600
      poolTimeout = 30
      idleTimeout = 300
      idleCheckFrequency = 60
    }
    
    # Object storage configuration
    objectStorage = {
      endpoint = "https://minio.btp-deps.svc.cluster.local:9000"
      bucket = "btp-artifacts"
      accessKey = "${MINIO_ACCESS_KEY}"
      secretKey = "${MINIO_SECRET_KEY}"
      region = "us-east-1"
      useSSL = true
      pathStyle = true
    }
    
    # Vault configuration
    vault = {
      endpoint = "https://vault.btp-deps.svc.cluster.local:8200"
      token = "${VAULT_TOKEN}"
      namespace = "btp"
      engine = "secret"
    }
    
    # OAuth configuration
    oauth = {
      issuer = "https://auth.btp.example.com/realms/btp"
      clientId = "btp-client"
      clientSecret = "${OAUTH_CLIENT_SECRET}"
      realm = "btp"
    }
    
    # Monitoring configuration
    monitoring = {
      prometheus = {
        enabled = true
        port = 9090
        path = "/metrics"
      }
      grafana = {
        enabled = true
        dashboard = "btp-platform"
      }
    }
    
    # Security configuration
    security = {
      cors = {
        allowedOrigins = ["https://btp.example.com"]
        allowedMethods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
        allowedHeaders = ["Authorization", "Content-Type"]
        allowCredentials = true
        maxAge = 3600
      }
      rateLimit = {
        enabled = true
        requestsPerMinute = 1000
        burstSize = 100
      }
      jwt = {
        issuer = "https://auth.btp.example.com/realms/btp"
        audience = "btp-client"
        algorithm = "RS256"
        expiresIn = "1h"
        refreshExpiresIn = "24h"
      }
    }
  }
}
```

### Custom Monitoring Configuration

#### Advanced Monitoring Setup
```hcl
# examples/custom-monitoring.tfvars
platform = "aws"
base_domain = "btp.example.com"
environment = "production"

metrics_logs = {
  mode = "k8s"
  k8s = {
    prometheus = {
      chart_version = "51.4.0"
      release_name  = "prometheus"
      replica_count = 2
      persistence = {
        enabled = true
        size = "100Gi"
        storageClass = "gp2"
      }
      values = {
        prometheus = {
          prometheusSpec = {
            retention = "30d"
            retentionSize = "50GB"
            storageSpec = {
              volumeClaimTemplate = {
                spec = {
                  storageClassName = "gp2"
                  accessModes = ["ReadWriteOnce"]
                  resources = {
                    requests = {
                      storage = "100Gi"
                    }
                  }
                }
              }
            }
            ruleSelector = {
              matchLabels = {
                "prometheus" = "btp"
                "role" = "alert-rules"
              }
            }
            serviceMonitorSelector = {
              matchLabels = {
                "prometheus" = "btp"
              }
            }
          }
        }
        alertmanager = {
          alertmanagerSpec = {
            resources = {
              requests = {
                memory = "256Mi"
                cpu = "250m"
              }
              limits = {
                memory = "512Mi"
                cpu = "500m"
              }
            }
          }
        }
      }
    }
    
    grafana = {
      chart_version = "7.0.12"
      release_name  = "grafana"
      admin_user    = "admin"
      admin_password = "secure-grafana-password"
      persistence = {
        enabled = true
        size = "10Gi"
        storageClass = "gp2"
      }
      values = {
        resources = {
          requests = {
            memory = "256Mi"
            cpu = "250m"
          }
          limits = {
            memory = "512Mi"
            cpu = "500m"
          }
        }
        grafana.ini = {
          server = {
            root_url = "https://grafana.btp.example.com"
          }
          security = {
            admin_user = "admin"
            admin_password = "secure-grafana-password"
          }
        }
        dashboardProviders = {
          "dashboardproviders.yaml" = {
            apiVersion = 1
            providers = [
              {
                name = "default"
                orgId = 1
                folder = ""
                type = "file"
                disableDeletion = false
                editable = true
                options = {
                  path = "/var/lib/grafana/dashboards/default"
                }
              }
            ]
          }
        }
        dashboards = {
          default = {
            "btp-overview" = {
              gnetId = 1860
              revision = 1
              datasource = "Prometheus"
            }
            "btp-kubernetes" = {
              gnetId = 315
              revision = 1
              datasource = "Prometheus"
            }
          }
        }
      }
    }
    
    loki = {
      chart_version = "5.45.0"
      release_name  = "loki"
      replica_count = 2
      persistence = {
        enabled = true
        size = "100Gi"
        storageClass = "gp2"
      }
      values = {
        loki = {
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
          config = {
            auth_enabled = false
            server = {
              http_listen_port = 3100
            }
            ingester = {
              lifecycler = {
                ring = {
                  kvstore = {
                    store = "inmemory"
                  }
                }
              }
            }
            schema_config = {
              configs = [
                {
                  from = "2020-10-24"
                  store = "boltdb-shipper"
                  object_store = "filesystem"
                  schema = "v11"
                  index = {
                    prefix = "index_"
                    period = "24h"
                  }
                }
              ]
            }
            storage_config = {
              boltdb_shipper = {
                active_index_directory = "/loki/boltdb-shipper-active"
                cache_location = "/loki/boltdb-shipper-cache"
                shared_store = "filesystem"
              }
              filesystem = {
                directory = "/loki/chunks"
              }
            }
            limits_config = {
              enforce_metric_name = false
              reject_old_samples = true
              reject_old_samples_max_age = "168h"
            }
          }
        }
      }
    }
  }
}
```

## Troubleshooting Examples

### Common Issues and Solutions

#### Pod Startup Issues
```bash
# Check pod status
kubectl get pods -A | grep -E "(Error|CrashLoopBackOff|ImagePullBackOff|Pending)"

# Check pod logs
kubectl logs -n settlemint deployment/btp-platform --previous

# Check pod events
kubectl describe pod -n settlemint -l app=btp-platform

# Check resource usage
kubectl top pods -n settlemint
kubectl top nodes

# Check persistent volumes
kubectl get pv,pvc -A
```

#### Database Connection Issues
```bash
# Check PostgreSQL status
kubectl get pods -n btp-deps | grep postgres
kubectl logs -n btp-deps deployment/postgres --tail=100

# Test database connectivity
kubectl run postgres-test --rm -i --tty --image postgres:15 -- psql -h postgres.btp-deps.svc.cluster.local -U btp_user -d btp

# Check database configuration
kubectl exec -n btp-deps deployment/postgres -- psql -U btp_user -d btp -c "SHOW ALL;"
```

#### Network Connectivity Issues
```bash
# Check service endpoints
kubectl get endpoints -A

# Test DNS resolution
kubectl run dns-test --rm -i --tty --image busybox -- nslookup postgres.btp-deps.svc.cluster.local

# Test network connectivity
kubectl run network-test --rm -i --tty --image busybox -- nc -zv postgres.btp-deps.svc.cluster.local 5432

# Check network policies
kubectl get networkpolicies -A
```

#### Certificate Issues
```bash
# Check certificate status
kubectl get certificates -A

# Check certificate details
kubectl describe certificate -n settlemint btp-tls

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# Force certificate renewal
kubectl annotate certificate btp-tls -n settlemint cert-manager.io/renew-before="24h" --overwrite
```

## Integration Examples

### CI/CD Integration

#### GitHub Actions Workflow
```yaml
# .github/workflows/deploy.yml
name: Deploy BTP Platform

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  TF_VAR_platform: "aws"
  TF_VAR_base_domain: "btp.example.com"
  TF_VAR_environment: "production"

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: 1.5.0
    
    - name: Setup AWS CLI
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-east-1
    
    - name: Setup kubectl
      uses: azure/setup-kubectl@v3
      with:
        version: 'v1.28.0'
    
    - name: Setup Helm
      uses: azure/setup-helm@v3
      with:
        version: 'v3.12.0'
    
    - name: Terraform Init
      run: terraform init
    
    - name: Terraform Plan
      run: terraform plan -var-file=examples/production.tfvars
      env:
        TF_VAR_license_username: ${{ secrets.LICENSE_USERNAME }}
        TF_VAR_license_password: ${{ secrets.LICENSE_PASSWORD }}
        TF_VAR_license_signature: ${{ secrets.LICENSE_SIGNATURE }}
        TF_VAR_license_email: ${{ secrets.LICENSE_EMAIL }}
        TF_VAR_jwt_signing_key: ${{ secrets.JWT_SIGNING_KEY }}
        TF_VAR_grafana_admin_password: ${{ secrets.GRAFANA_ADMIN_PASSWORD }}
    
    - name: Terraform Apply
      if: github.ref == 'refs/heads/main'
      run: terraform apply -auto-approve -var-file=examples/production.tfvars
      env:
        TF_VAR_license_username: ${{ secrets.LICENSE_USERNAME }}
        TF_VAR_license_password: ${{ secrets.LICENSE_PASSWORD }}
        TF_VAR_license_signature: ${{ secrets.LICENSE_SIGNATURE }}
        TF_VAR_license_email: ${{ secrets.LICENSE_EMAIL }}
        TF_VAR_jwt_signing_key: ${{ secrets.JWT_SIGNING_KEY }}
        TF_VAR_grafana_admin_password: ${{ secrets.GRAFANA_ADMIN_PASSWORD }}
    
    - name: Verify Deployment
      if: github.ref == 'refs/heads/main'
      run: |
        kubectl get pods -A
        kubectl get svc -A
        kubectl get ingress -A
        curl -f https://btp.example.com/health
```

#### GitLab CI/CD Pipeline
```yaml
# .gitlab-ci.yml
stages:
  - plan
  - deploy
  - verify

variables:
  TF_VAR_platform: "aws"
  TF_VAR_base_domain: "btp.example.com"
  TF_VAR_environment: "production"

terraform:plan:
  stage: plan
  image: hashicorp/terraform:1.5.0
  before_script:
    - apk add --no-cache curl
    - curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    - chmod +x kubectl && mv kubectl /usr/local/bin/
    - curl -LO "https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz"
    - tar -zxvf helm-v3.12.0-linux-amd64.tar.gz
    - mv linux-amd64/helm /usr/local/bin/helm
  script:
    - terraform init
    - terraform plan -var-file=examples/production.tfvars
  only:
    - merge_requests

terraform:deploy:
  stage: deploy
  image: hashicorp/terraform:1.5.0
  before_script:
    - apk add --no-cache curl
    - curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    - chmod +x kubectl && mv kubectl /usr/local/bin/
    - curl -LO "https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz"
    - tar -zxvf helm-v3.12.0-linux-amd64.tar.gz
    - mv linux-amd64/helm /usr/local/bin/helm
  script:
    - terraform init
    - terraform apply -auto-approve -var-file=examples/production.tfvars
  only:
    - main
  environment:
    name: production
    url: https://btp.example.com

verify:deployment:
  stage: verify
  image: curlimages/curl:latest
  script:
    - kubectl get pods -A
    - kubectl get svc -A
    - kubectl get ingress -A
    - curl -f https://btp.example.com/health
  only:
    - main
  needs:
    - terraform:deploy
```

### Monitoring Integration

#### Prometheus Alerting Rules
```yaml
# monitoring/alerts.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: btp-platform-alerts
  namespace: btp-deps
spec:
  groups:
  - name: btp-platform.critical
    rules:
    - alert: BTPPlatformDown
      expr: up{job="btp-platform"} == 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "BTP Platform is down"
        description: "BTP Platform has been down for more than 1 minute"
    
    - alert: BTPHighCPUUsage
      expr: rate(container_cpu_usage_seconds_total{namespace="settlemint"}[5m]) * 100 > 80
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High CPU usage in BTP Platform"
        description: "CPU usage is above 80% for more than 5 minutes"
    
    - alert: BTPHighMemoryUsage
      expr: container_memory_usage_bytes{namespace="settlemint"} / container_spec_memory_limit_bytes * 100 > 85
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High memory usage in BTP Platform"
        description: "Memory usage is above 85% for more than 5 minutes"
    
    - alert: BTPDatabaseDown
      expr: up{job="postgres"} == 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "PostgreSQL database is down"
        description: "PostgreSQL database has been down for more than 1 minute"
    
    - alert: BTPRedisDown
      expr: up{job="redis"} == 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "Redis is down"
        description: "Redis has been down for more than 1 minute"
```

#### Grafana Dashboard
```json
{
  "dashboard": {
    "title": "BTP Platform Overview",
    "panels": [
      {
        "title": "CPU Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(container_cpu_usage_seconds_total{namespace=\"settlemint\"}[5m]) * 100",
            "legendFormat": "CPU Usage %"
          }
        ]
      },
      {
        "title": "Memory Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "container_memory_usage_bytes{namespace=\"settlemint\"} / container_spec_memory_limit_bytes * 100",
            "legendFormat": "Memory Usage %"
          }
        ]
      },
      {
        "title": "HTTP Requests",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total{namespace=\"settlemint\"}[5m])",
            "legendFormat": "Requests/sec"
          }
        ]
      },
      {
        "title": "Error Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total{namespace=\"settlemint\",status=~\"5..\"}[5m]) / rate(http_requests_total{namespace=\"settlemint\"}[5m])",
            "legendFormat": "Error Rate"
          }
        ]
      }
    ]
  }
}
```

## Next Steps

- [FAQ](24-faq.md) - Frequently asked questions
- [Contributing](25-contributing.md) - Contributing guidelines

---

*This Examples document provides comprehensive real-world examples for deploying the SettleMint BTP platform. Use these examples as starting points for your own deployments and customize them according to your specific requirements.*
