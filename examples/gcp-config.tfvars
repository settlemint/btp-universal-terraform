# GCP configuration example - using managed GCP services
# Deploy dependencies via Cloud SQL, Memorystore, Cloud Storage, etc.

platform = "gcp"

base_domain = "tf.gcp.settlemint.com" # Your actual domain

# Kubernetes Cluster Configuration - Creates GCP GKE cluster
k8s_cluster = {
  mode = "gcp"
  gcp = {
    cluster_name       = "btp-gke"
    project_id         = "settlemint-customer-success"
    region             = "us-central1"
    kubernetes_version = "1.31"
    network            = "default"
    subnetwork         = "default"

    # IP allocation for pods and services (auto-create secondary ranges)
    ip_allocation_policy = {
      cluster_secondary_range_name  = null               # Don't use named ranges
      services_secondary_range_name = null               # Don't use named ranges
      cluster_ipv4_cidr_block       = "10.4.0.0/14"      # Pods
      services_ipv4_cidr_block      = "10.0.32.0/20"     # Services
    }

    # Node pools
    node_pools = {
      default = {
        node_count     = null # Use auto-scaling
        min_node_count = 1
        max_node_count = 6
        auto_scaling   = true
        machine_type   = "e2-standard-4"
        disk_size_gb   = 100
      }
    }

    # Features
    enable_workload_identity          = true
    enable_http_load_balancing        = true
    enable_horizontal_pod_autoscaling = true
    enable_network_policy             = true
    enable_cloud_logging              = true
    enable_cloud_monitoring           = true
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

# PostgreSQL via GCP Cloud SQL
postgres = {
  mode = "gcp"
  gcp = {
    project_id       = "settlemint-customer-success"
    instance_name    = "btp-postgres"
    database_version = "POSTGRES_15"
    region           = "us-central1"
    tier             = "db-f1-micro"
    database         = "btp"
    username         = "postgres"
    # password         = "override-via-env" # Use TF_VAR_postgres_password

    # Allow connections from anywhere (for testing - use private networking in production)
    ipv4_enabled = true
    authorized_networks = [
      {
        name  = "allow-all"
        value = "0.0.0.0/0"
      }
    ]
  }
}

# Redis via GCP Memorystore
redis = {
  mode = "gcp"
  gcp = {
    project_id     = "my-gcp-project"
    instance_name  = "btp-redis"
    tier           = "BASIC"
    memory_size_gb = 1
    region         = "us-central1"
    redis_version  = "REDIS_7_0"
  }
}

# Object Storage via GCP Cloud Storage
object_storage = {
  mode = "gcp"
  gcp = {
    project_id    = "settlemint-customer-success"
    bucket_name   = null # Auto-generated from base_domain
    location      = "US"
    storage_class = "STANDARD"
    # access_key and secret_key will be auto-generated via HMAC
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
  }
}

# Metrics/Logs - Keep in Kubernetes
metrics_logs = {
  mode = "k8s"
  k8s = {
    release_name_kps         = "kps"
    release_name_loki        = "loki"
    kp_stack_chart_version   = "55.8.2"
    loki_stack_chart_version = "2.9.11"
  }
}

# OAuth via GCP Identity Platform
oauth = {
  mode = "gcp"
  gcp = {
    project_id = "settlemint-customer-success"
    # client_id     = "xxxxx"
    # client_secret = "xxxxx"
    callback_urls = ["https://tf.gcp.settlemint.com/auth/callback"]
  }
}

# DNS via GCP Cloud DNS
dns = {
  mode = "gcp"
  gcp = {
    project              = "settlemint-customer-success"
    managed_zone         = "gcp-settlemint-com" # Name of your Cloud DNS managed zone
    main_record_value    = "127.0.0.1"     # Placeholder - update after getting ingress IP
    main_record_type     = "A"
    wildcard_record_type = "CNAME"
    # wildcard_record_value defaults to base_domain
  }
}

# Secrets via GCP Secret Manager (service account-based)
secrets = {
  mode = "gcp"
  gcp = {
    project_id = "settlemint-customer-success"
  }
}

# BTP Platform deployment
btp = {
  enabled       = true
  chart         = "oci://harbor.settlemint.com/settlemint/settlemint"
  namespace     = "settlemint"
  release_name  = "settlemint-platform"
  chart_version = "v7.32.10"
  # values_file   = "prod-values.yaml"
}
