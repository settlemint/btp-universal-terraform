# Mixed configuration example - using different providers for different services
# This demonstrates the flexibility of the multi-cloud architecture:
# - AWS EKS for Kubernetes cluster
# - AWS RDS for PostgreSQL
# - Azure Cache for Redis (cross-cloud)
# - GCP Cloud Storage for object storage (cross-cloud)
# - K8s-based ingress and metrics
# - BYO (Bring Your Own) for secrets (existing Vault instance)

platform = "aws" # Primary platform

base_domain = "btp.example.com"

# VPC Configuration - AWS infrastructure foundation
vpc = {
  aws = {
    create_vpc         = true
    vpc_name           = "btp-vpc"
    vpc_cidr           = "10.0.0.0/16"
    region             = "us-east-1"
    availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
    enable_nat_gateway = true
    single_nat_gateway = true
    enable_s3_endpoint = true
  }
}

# Kubernetes Cluster - AWS EKS
k8s_cluster = {
  mode = "aws"
  aws = {
    cluster_name    = "btp-eks"
    cluster_version = "1.31"
    region          = "us-east-1"

    node_groups = {
      default = {
        desired_size   = 3
        min_size       = 2
        max_size       = 5
        instance_types = ["t3.large"]
        capacity_type  = "ON_DEMAND"
        disk_size      = 100
      }
      # Optional: Add spot instances for non-critical workloads
      spot = {
        desired_size   = 2
        min_size       = 0
        max_size       = 4
        instance_types = ["t3.large", "t3a.large"]
        capacity_type  = "SPOT"
        disk_size      = 100
        labels = {
          workload = "spot"
        }
        taints = [{
          key    = "spot"
          value  = "true"
          effect = "NoSchedule"
        }]
      }
    }

    enable_irsa                         = true
    enable_ebs_csi_driver               = true
    enable_aws_load_balancer_controller = true
    enable_cluster_autoscaler           = true
    endpoint_private_access             = true
    endpoint_public_access              = true
    enable_secrets_encryption           = true
  }
}

namespaces = {
  ingress_tls    = "btp-deps"
  postgres       = "btp-deps"
  redis          = "btp-deps"
  object_storage = "btp-deps"
  metrics_logs   = "btp-deps"
  oauth          = "btp-deps"
  secrets        = "btp-deps"
}

# PostgreSQL - AWS RDS (same cloud as K8s cluster for low latency)
postgres = {
  mode = "aws"
  aws = {
    identifier        = "btp-postgres"
    instance_class    = "db.r5.large"
    allocated_storage = 100
    engine_version    = "15.14"
    database          = "btp"
    username          = "postgres"
    # VPC/subnet/security groups auto-injected from VPC module
    skip_final_snapshot             = false # Production: take final snapshot
    backup_retention_period         = 30    # 30 days of backups
    performance_insights_enabled    = true
    enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
    auto_minor_version_upgrade      = true
    storage_encrypted               = true
  }
}

# Redis - Azure Cache for Redis (demonstrating cross-cloud capability)
# Useful if you have existing Azure infrastructure or prefer Azure's Redis pricing
redis = {
  mode = "azure"
  azure = {
    name                = "btp-redis"
    resource_group_name = "btp-resources"
    location            = "eastus"
    capacity            = 1
    family              = "P" # Premium tier for VNet support
    sku_name            = "Premium"
    # For production: enable geo-replication, persistence, and clustering
    enable_non_ssl_port           = false
    minimum_tls_version           = "1.2"
    public_network_access_enabled = false # Use private endpoint
    # subnet_id = "..." # Provide subnet for VNet integration
  }
}

# Object Storage - GCP Cloud Storage (demonstrating multi-cloud)
# Useful if you have data residency requirements in GCP regions
object_storage = {
  mode = "gcp"
  gcp = {
    bucket_name        = "btp-artifacts-gcp"
    project_id         = "my-gcp-project"
    location           = "US" # Multi-region for high availability
    storage_class      = "STANDARD"
    versioning_enabled = true
    # Lifecycle rules for cost optimization
    lifecycle_rules = [{
      action = {
        type          = "SetStorageClass"
        storage_class = "NEARLINE"
      }
      condition = {
        age = 30 # Move to Nearline after 30 days
      }
      }, {
      action = {
        type          = "SetStorageClass"
        storage_class = "COLDLINE"
      }
      condition = {
        age = 90 # Move to Coldline after 90 days
      }
      }, {
      action = {
        type = "Delete"
      }
      condition = {
        age = 365 # Delete after 1 year
      }
    }]
  }
}

# Ingress/TLS - Kubernetes-based (works with any K8s cluster)
ingress_tls = {
  mode = "k8s"
  k8s = {
    release_name_nginx         = "ingress"
    release_name_cert_manager  = "cert-manager"
    nginx_chart_version        = "4.10.1"
    cert_manager_chart_version = "v1.14.4"
    issuer_name                = "letsencrypt-prod"
    # For AWS: use NLB instead of NodePort
    values_nginx = {
      controller = {
        service = {
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type"                              = "nlb"
            "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
          }
        }
      }
    }
  }
}

# Metrics/Logs - Kubernetes-based with persistent storage
metrics_logs = {
  mode = "k8s"
  k8s = {
    release_name_kps         = "kps"
    release_name_loki        = "loki"
    kp_stack_chart_version   = "55.8.2"
    loki_stack_chart_version = "2.9.11"
    values = {
      prometheus = {
        prometheusSpec = {
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp3"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "50Gi"
                  }
                }
              }
            }
          }
          retention = "30d"
        }
      }
      grafana = {
        persistence = {
          enabled          = true
          storageClassName = "gp3"
          size             = "10Gi"
        }
      }
    }
  }
}

# OAuth - AWS Cognito (integrates well with EKS IRSA)
oauth = {
  mode = "aws"
  aws = {
    region         = "us-east-1"
    user_pool_name = "btp-users"
    client_name    = "btp-client"
    callback_urls  = ["https://btp.example.com/auth/callback"]
    # Enhanced security settings for production
    password_policy = {
      minimum_length    = 12
      require_lowercase = true
      require_uppercase = true
      require_numbers   = true
      require_symbols   = true
    }
    mfa_configuration        = "OPTIONAL"
    auto_verified_attributes = ["email"]
    # Email configuration for production
    email_configuration = {
      email_sending_account = "DEVELOPER" # Use SES
      # source_arn = "arn:aws:ses:us-east-1:123456789012:identity/noreply@example.com"
      # from_email_address = "noreply@example.com"
    }
  }
}

# Secrets - BYO existing HashiCorp Vault instance
# Useful if you have an existing enterprise Vault deployment
secrets = {
  mode = "byo"
  byo = {
    vault_addr = "https://vault.example.com:8200"
    # Token should be provided via TF_VAR_secrets_vault_token env var
    kv_mount = "btp-secrets"
    paths = [
      "database/postgres",
      "cache/redis",
      "storage/s3",
      "oauth/credentials"
    ]
  }
}

# Alternative: Use AWS Secrets Manager for secrets
# secrets = {
#   mode = "aws"
#   aws = {
#     region = "us-east-1"
#   }
# }

# BTP Platform deployment
btp = {
  enabled       = true
  chart         = "oci://registry.example.com/settlemint-platform/SettleMint"
  namespace     = "settlemint"
  release_name  = "settlemint-platform"
  chart_version = "7.0.0"
  # values_file   = "mixed-values.yaml"
}
