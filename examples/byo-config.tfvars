# BYO (Bring Your Own) configuration example
# Use this when you have existing infrastructure and want to connect BTP to it
# All services use existing resources that you already have deployed

platform = "generic" # Not using any specific cloud provider

base_domain = "btp.yourcompany.com"

# No VPC needed - using existing infrastructure
vpc = {}

# Kubernetes Cluster - Use existing cluster via kubeconfig
k8s_cluster = {
  mode = "byo"
  byo = {
    # Option 1: Path to kubeconfig file
    kubeconfig_path = "~/.kube/config"

    # Option 2: Base64 encoded kubeconfig content (useful for CI/CD)
    # kubeconfig_content = "base64_encoded_kubeconfig_here"

    # Optional: Specify which context to use from kubeconfig
    context_name = "my-production-cluster"
  }
}

# Alternative: Use existing EKS cluster without creating new one
# k8s_cluster = {
#   mode = "aws"
#   aws = {
#     cluster_name = "existing-eks-cluster"
#     region       = "us-east-1"
#     # Set existing VPC details
#     existing_vpc_id             = "vpc-xxxxx"
#     existing_private_subnet_ids = ["subnet-xxxxx", "subnet-yyyyy"]
#   }
# }

namespaces = {
  ingress_tls    = "btp-deps"
  postgres       = "btp-deps"
  redis          = "btp-deps"
  object_storage = "btp-deps"
  metrics_logs   = "btp-deps"
  oauth          = "btp-deps"
  secrets        = "btp-deps"
}

# PostgreSQL - Use existing PostgreSQL database
postgres = {
  mode = "byo"
  byo = {
    host     = "postgres.yourcompany.com"
    port     = 5432
    database = "btp_production"
    username = "btp_user"
    # Password should be provided via TF_VAR_postgres_password env var
    # or use connection string with embedded credentials
    # connection_string = "postgresql://user:pass@host:5432/dbname?sslmode=require"
    ssl_mode = "require"
  }
}

# Redis - Use existing Redis instance (could be AWS ElastiCache, Azure Cache, self-hosted, etc.)
redis = {
  mode = "byo"
  byo = {
    host = "redis.yourcompany.com"
    port = 6379
    # Password via TF_VAR_redis_password if auth is enabled
    # password = "..."
    scheme      = "rediss" # Use TLS
    tls_enabled = true
    # For Redis Cluster
    # cluster_mode = true
    # nodes = ["redis-node1:6379", "redis-node2:6379", "redis-node3:6379"]
  }
}

# Object Storage - Use existing S3-compatible storage (AWS S3, MinIO, Ceph, etc.)
object_storage = {
  mode = "byo"
  byo = {
    endpoint = "https://s3.yourcompany.com" # Or AWS: "https://s3.us-east-1.amazonaws.com"
    bucket   = "btp-artifacts"
    region   = "us-east-1" # For AWS S3
    # Credentials via TF_VAR_object_storage_access_key and TF_VAR_object_storage_secret_key
    # access_key     = "..."
    # secret_key     = "..."
    use_path_style = false # true for MinIO/Ceph, false for AWS S3
  }
}

# Ingress/TLS - Deploy in Kubernetes (works with any cluster)
ingress_tls = {
  mode = "k8s"
  k8s = {
    release_name_nginx         = "ingress"
    release_name_cert_manager  = "cert-manager"
    nginx_chart_version        = "4.10.1"
    cert_manager_chart_version = "v1.14.4"
    issuer_name                = "letsencrypt-prod"

    # Customize for your environment
    values_nginx = {
      controller = {
        service = {
          type = "LoadBalancer"
          # Or use NodePort if you have external load balancer
          # type = "NodePort"
        }
        # If using an existing ingress controller, you can skip this
        ingressClassResource = {
          name    = "nginx"
          default = true
        }
      }
    }
  }
}

# Metrics/Logs - Use existing Prometheus/Grafana/Loki
# Option 1: Deploy in K8s
metrics_logs = {
  mode = "k8s"
  k8s = {
    release_name_kps         = "kps"
    release_name_loki        = "loki"
    kp_stack_chart_version   = "55.8.2"
    loki_stack_chart_version = "2.9.11"
  }
}

# Option 2: Use existing monitoring stack (BYO)
# metrics_logs = {
#   mode = "byo"
#   byo = {
#     prometheus_url = "https://prometheus.yourcompany.com"
#     grafana_url    = "https://grafana.yourcompany.com"
#     loki_url       = "https://loki.yourcompany.com"
#   }
# }

# OAuth - Use existing identity provider
oauth = {
  mode = "byo"
  byo = {
    # OIDC configuration for existing identity provider
    # (Keycloak, Okta, Auth0, Azure AD, Google, etc.)
    issuer    = "https://auth.yourcompany.com/realms/production"
    client_id = "btp-production"
    # Client secret via TF_VAR_oauth_client_secret
    # client_secret = "..."
    scopes        = ["openid", "email", "profile"]
    callback_urls = ["https://btp.yourcompany.com/auth/callback"]

    # Optional: Admin URL for user management
    admin_url = "https://auth.yourcompany.com/admin"
  }
}

# Alternative: Disable OAuth if not needed
# oauth = {
#   mode = "disabled"
# }

# Secrets - Use existing HashiCorp Vault
secrets = {
  mode = "byo"
  byo = {
    vault_addr = "https://vault.yourcompany.com:8200"
    # Token via TF_VAR_secrets_vault_token
    # For production, use Kubernetes auth or AppRole instead
    kv_mount = "secret"
    paths = [
      "btp/database",
      "btp/redis",
      "btp/storage",
      "btp/oauth"
    ]
  }
}

# Alternative: Use Kubernetes secrets (not recommended for production)
# secrets = {
#   mode = "k8s"
#   k8s = {
#     # Secrets will be stored as K8s secrets
#     # Consider using external-secrets operator for production
#   }
# }

# BTP Platform deployment
btp = {
  enabled       = true
  chart         = "oci://registry.example.com/settlemint-platform/SettleMint"
  namespace     = "settlemint-production"
  release_name  = "settlemint-platform"
  chart_version = "7.0.0"
  # values_file   = "production-values.yaml"
}
