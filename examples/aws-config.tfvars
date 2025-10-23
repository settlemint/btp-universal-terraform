# AWS configuration example - using managed AWS services
# Deploy dependencies via RDS, ElastiCache, S3, etc.

platform = "aws"

base_domain = "btp.aws.example.com"

# VPC Configuration - Creates a dedicated VPC for BTP infrastructure
vpc = {
  aws = {
    create_vpc         = true
    vpc_name           = "btp-vpc"
    vpc_cidr           = "10.0.0.0/16"
    region             = "eu-central-1"
    availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
    enable_nat_gateway = true
    single_nat_gateway = true # Set to false for HA across AZs (costs more)
    enable_s3_endpoint = true # Reduces data transfer costs for S3
  }
}

# Kubernetes Cluster Configuration - Creates AWS EKS cluster
k8s_cluster = {
  mode = "aws"
  aws = {
    cluster_name    = "btp-eks"
    cluster_version = "1.33"
    region          = "eu-central-1"
    # VPC and subnet IDs are auto-injected from VPC module

    # Node groups - 3 node cluster for testing
    node_groups = {
      default = {
        desired_size   = 3
        min_size       = 3
        max_size       = 3
        instance_types = ["t3.medium"]
        capacity_type  = "ON_DEMAND"
        disk_size      = 50
      }
    }

    # Cluster features
    enable_irsa                         = true # IAM Roles for Service Accounts
    enable_ebs_csi_driver               = true # Required for persistent volumes
    enable_aws_load_balancer_controller = true # Enable for LoadBalancer ingress
    enable_cluster_autoscaler           = false

    # Access
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"] # Restrict this in production

    # Security
    enable_secrets_encryption = true
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

# PostgreSQL via AWS RDS
postgres = {
  mode = "aws"
  aws = {
    identifier        = "btp-postgres"
    instance_class    = "db.t3.small"
    allocated_storage = 50
    engine_version    = "15.14"
    database          = "btp"
    username          = "postgres"
    # password is set via TF_VAR_postgres_password environment variable
    skip_final_snapshot = true
    # VPC/subnet/security group IDs are auto-injected from VPC module
  }
}

# Redis via AWS ElastiCache
redis = {
  mode = "aws"
  aws = {
    cluster_id     = "btp-redis"
    node_type      = "cache.t3.micro"
    engine_version = "7.0"
    # VPC/subnet/security group IDs are auto-injected from VPC module
  }
}

# Object Storage via AWS S3
object_storage = {
  mode = "aws"
  aws = {
    region             = "eu-central-1"
    versioning_enabled = true
    # bucket_name        = "custom-btp-artifacts" # Optional fixed bucket name override
    # manage_bucket      = false                   # Uncomment to reuse an existing bucket without recreating it
    # access_key         = "AKIAXXXXX"      # Use TF_VAR_object_storage_access_key
    # secret_key         = "secret"         # Use TF_VAR_object_storage_secret_key
  }
}

# DNS automation via Route53
dns = {
  mode                    = "aws"
  domain                  = "btp.aws.example.com"
  enable_wildcard         = true
  include_wildcard_in_tls = true
  # Production issuer for trusted certificates
  cert_manager_issuer = "letsencrypt-prod"
  ssl_redirect        = false
  aws = {
    zone_name = "aws.example.com"
    main_ttl  = 300
  }
}

# Ingress/TLS - Keep in Kubernetes (cert-manager + nginx)
ingress_tls = {
  mode = "k8s"
  k8s = {
    release_name_nginx         = "ingress"
    release_name_cert_manager  = "cert-manager"
    nginx_chart_version        = "4.10.1"
    cert_manager_chart_version = "v1.14.4"
    issuer_name                = "letsencrypt-prod"
    # Switch to production for trusted certificates.
    acme_environment = "production"
    # Override service type to LoadBalancer for AWS
    values_nginx = {
      controller = {
        service = {
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
          }
        }
        config = {
          "allow-snippet-annotations" = "true"
        }
      }
    }
  }
}

# Metrics/Logs - Disabled for this configuration
metrics_logs = {
  mode = "disabled"
}

# OAuth via AWS Cognito
oauth = {
  mode = "aws"
  aws = {
    region         = "eu-central-1"
    user_pool_name = "btp-users"
    client_name    = "btp-client"
    domain_prefix  = "btp-example-platform"
    # user_pool_id   = "eu-central-1_xxxxx" # If using existing pool
    # client_id      = "xxxxx"
    # client_secret  = "xxxxx"
    callback_urls = ["https://btp.aws.example.com/api/auth/callback/cognito"]
  }
}

# Secrets via AWS Secrets Manager (IAM-based, no explicit config needed)
secrets = {
  mode = "aws"
  aws = {
    region = "eu-central-1"
  }
}

# BTP Platform deployment
btp = {
  enabled       = true
  chart         = "oci://harbor.settlemint.com/settlemint/settlemint"
  namespace     = "settlemint"
  release_name  = "settlemint-platform"
  chart_version = "v7.32.10"
}
