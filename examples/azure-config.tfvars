# Azure configuration example - using managed Azure services
# Deploy dependencies via Azure Database, Cache for Redis, Blob Storage, etc.

platform = "azure"

cluster = {
  create          = false # Set to true to create AKS cluster, false to use existing
  kubeconfig_path = null  # Path to kubeconfig or null to use current context
  # name            = "btp-cluster"
  # version         = "1.28"
  # region          = "eastus"
}

base_domain = "btp.example.com" # Your actual domain

namespaces = {
  ingress_tls    = "btp-deps"
  postgres       = "btp-deps"
  redis          = "btp-deps"
  object_storage = "btp-deps"
  metrics_logs   = "btp-deps"
  oauth          = "btp-deps"
  secrets        = "btp-deps"
}

# PostgreSQL via Azure Database for PostgreSQL
postgres = {
  mode = "azure"
  azure = {
    server_name         = "btp-postgres"
    resource_group_name = "btp-resources"
    location            = "eastus"
    version             = "15"
    sku_name            = "B_Standard_B1ms"
    storage_mb          = 32768
    database            = "btp"
    admin_username      = "postgres"
    # admin_password      = "override-via-env" # Use TF_VAR_postgres_admin_password
  }
}

# Redis via Azure Cache for Redis
redis = {
  mode = "azure"
  azure = {
    cache_name          = "btp-redis"
    resource_group_name = "btp-resources"
    location            = "eastus"
    capacity            = 0
    family              = "C"
    sku_name            = "Basic"
    ssl_enabled         = true
  }
}

# Object Storage via Azure Blob Storage
object_storage = {
  mode = "azure"
  azure = {
    storage_account_name = "btpstorage"
    container_name       = "btp-artifacts"
    resource_group_name  = "btp-resources"
    location             = "eastus"
    account_tier         = "Standard"
    replication_type     = "LRS"
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

# OAuth via Azure AD B2C
oauth = {
  mode = "azure"
  azure = {
    tenant_name         = "btptenant"
    resource_group_name = "btp-resources"
    location            = "United States"
    domain_name         = "btptenant.onmicrosoft.com"
    # tenant_id           = "xxxxx-xxxxx-xxxxx"
    # client_id           = "xxxxx"
    # client_secret       = "xxxxx"
    callback_urls       = ["https://btp.example.com/auth/callback"]
  }
}

# Secrets via Azure Key Vault
secrets = {
  mode = "azure"
  azure = {
    key_vault_name      = "btp-keyvault"
    resource_group_name = "btp-resources"
    location            = "eastus"
    # tenant_id           = "xxxxx-xxxxx-xxxxx"
    sku_name            = "standard"
  }
}

# BTP Platform deployment
btp = {
  enabled       = true
  chart         = "oci://registry.settlemint.com/settlemint-platform/SettleMint"
  namespace     = "settlemint"
  release_name  = "settlemint-platform"
  chart_version = "7.0.0"
  # values_file   = "prod-values.yaml"
}
