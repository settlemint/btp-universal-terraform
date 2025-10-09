locals {
  # Default namespace for all dependencies
  default_namespace = "btp-deps"

  # Simplified namespace resolution with clear precedence:
  # 1. Component-specific k8s.namespace
  # 2. Global namespace map
  # 3. Default namespace
  namespaces = {
    ingress_tls    = coalesce(try(var.ingress_tls.k8s.namespace, null), var.namespaces.ingress_tls, local.default_namespace)
    postgres       = coalesce(try(var.postgres.k8s.namespace, null), var.namespaces.postgres, local.default_namespace)
    redis          = coalesce(try(var.redis.k8s.namespace, null), var.namespaces.redis, local.default_namespace)
    object_storage = coalesce(try(var.object_storage.k8s.namespace, null), var.namespaces.object_storage, local.default_namespace)
    metrics_logs   = coalesce(try(var.metrics_logs.k8s.namespace, null), var.namespaces.metrics_logs, local.default_namespace)
    oauth          = coalesce(try(var.oauth.k8s.namespace, null), var.namespaces.oauth, local.default_namespace)
    secrets        = coalesce(try(var.secrets.k8s.namespace, null), var.namespaces.secrets, local.default_namespace)
  }

  # OAuth configuration
  oauth_enabled = try(var.oauth.mode, "disabled") != "disabled"

  # Default null OAuth outputs
  oauth_null_outputs = {
    issuer        = null
    admin_url     = null
    client_id     = null
    client_secret = null
    scopes        = []
    callback_urls = []
  }

  # Select OAuth outputs based on whether module is enabled
  oauth_outputs = local.oauth_enabled && length(module.oauth) > 0 ? module.oauth[0] : local.oauth_null_outputs

  # Dependency namespaces set (includes oauth only if enabled)
  dep_namespaces = toset(
    compact([
      local.namespaces.ingress_tls,
      local.namespaces.postgres,
      local.namespaces.redis,
      local.namespaces.object_storage,
      local.namespaces.metrics_logs,
      local.oauth_enabled ? local.namespaces.oauth : null,
      local.namespaces.secrets
    ])
  )
}

# VPC Module - Creates dedicated VPC for AWS deployments
module "vpc" {
  source = "./deps/vpc"

  mode = var.platform
  aws  = try(var.vpc.aws, {})
}

# Kubernetes Cluster Module - Creates managed K8s cluster (EKS, AKS, GKE) or uses existing cluster
# Deployed after VPC but before all other dependencies
module "k8s_cluster" {
  source = "./deps/k8s_cluster"

  mode = try(var.k8s_cluster.mode, "disabled")
  aws = merge(
    try(var.k8s_cluster.aws, {}),
    {
      vpc_id     = module.vpc.vpc_id
      subnet_ids = module.vpc.private_subnet_ids
    }
  )
  azure = try(var.k8s_cluster.azure, {})
  gcp   = try(var.k8s_cluster.gcp, {})
  byo   = try(var.k8s_cluster.byo, null)

  depends_on = [module.vpc]
}

# Pre-destroy hook: Clean up Kubernetes LoadBalancers before destroying cluster
# This prevents orphaned ENIs from blocking subnet/VPC deletion
resource "null_resource" "cleanup_k8s_loadbalancers" {
  # Only create this resource when using managed K8s cluster (not BYO)
  count = contains(["aws", "azure", "gcp"], try(var.k8s_cluster.mode, "disabled")) ? 1 : 0

  triggers = {
    cluster_id = module.k8s_cluster.cluster_name
    region     = try(var.k8s_cluster.aws.region, try(var.k8s_cluster.azure.location, try(var.k8s_cluster.gcp.region, "")))
    mode       = try(var.k8s_cluster.mode, "disabled")
  }

  # This provisioner runs BEFORE this resource is destroyed
  # Which happens BEFORE the cluster is destroyed (due to depends_on)
  provisioner "local-exec" {
    when       = destroy
    on_failure = continue
    command    = <<-EOT
      echo "🧹 Cleaning up Kubernetes LoadBalancers to prevent orphaned ENIs..."

      # Set KUBECONFIG to use the generated kubeconfig file
      export KUBECONFIG="${path.root}/.terraform/kubeconfig-${self.triggers.mode}"

      # Delete all LoadBalancer services across all namespaces
      # Note: --all and --field-selector cannot be used together
      kubectl delete svc -A --field-selector spec.type=LoadBalancer --timeout=120s 2>/dev/null || true

      # Wait for cloud provider to clean up ENIs/load balancers
      echo "⏳ Waiting 30s for cloud provider to clean up network interfaces..."
      sleep 30

      echo "✅ Kubernetes LoadBalancer cleanup complete"
    EOT
  }

  depends_on = [
    module.k8s_cluster,
    module.ingress_tls,
    module.metrics_logs
  ]
}

resource "kubernetes_namespace" "deps" {
  for_each = local.dep_namespaces

  metadata {
    name = each.value
    labels = {
      "btp.smint.io/platform" = var.platform
    }
  }

  depends_on = [
    module.k8s_cluster
  ]
}

module "ingress_tls" {
  source = "./deps/ingress_tls"

  mode                       = try(var.ingress_tls.mode, "k8s")
  namespace                  = local.namespaces.ingress_tls
  manage_namespace           = false
  nginx_chart_version        = try(var.ingress_tls.k8s.nginx_chart_version, null)
  cert_manager_chart_version = try(var.ingress_tls.k8s.cert_manager_chart_version, null)
  release_name_nginx         = try(var.ingress_tls.k8s.release_name_nginx, null)
  release_name_cert_manager  = try(var.ingress_tls.k8s.release_name_cert_manager, null)
  issuer_name                = try(var.ingress_tls.k8s.issuer_name, null)
  values_nginx               = try(var.ingress_tls.k8s.values_nginx, {})
  values_cert_manager        = try(var.ingress_tls.k8s.values_cert_manager, {})
  kubeconfig_path            = local.kubeconfig_path

  depends_on = [kubernetes_namespace.deps]
}

module "postgres" {
  source = "./deps/postgres"

  mode             = try(var.postgres.mode, "k8s")
  namespace        = local.namespaces.postgres
  manage_namespace = false
  k8s              = try(var.postgres.k8s, {})
  aws = merge(
    try(var.postgres.aws, {}),
    {
      subnet_ids         = module.vpc.private_subnet_ids
      security_group_ids = module.vpc.rds_security_group_id != null ? [module.vpc.rds_security_group_id] : []
    }
  )
  azure = try(var.postgres.azure, {})
  gcp   = try(var.postgres.gcp, {})
  byo   = try(var.postgres.byo, null)

  depends_on = [module.vpc]
}

module "redis" {
  source = "./deps/redis"

  mode             = try(var.redis.mode, "k8s")
  namespace        = local.namespaces.redis
  manage_namespace = false
  k8s              = try(var.redis.k8s, {})
  aws = merge(
    try(var.redis.aws, {}),
    {
      subnet_ids         = module.vpc.private_subnet_ids
      security_group_ids = module.vpc.elasticache_security_group_id != null ? [module.vpc.elasticache_security_group_id] : []
    }
  )
  azure = try(var.redis.azure, {})
  gcp   = try(var.redis.gcp, {})
  byo   = try(var.redis.byo, null)

  depends_on = [module.vpc]
}

module "object_storage" {
  source = "./deps/object_storage"

  mode             = try(var.object_storage.mode, "k8s")
  namespace        = local.namespaces.object_storage
  manage_namespace = false
  k8s              = try(var.object_storage.k8s, {})
  aws              = try(var.object_storage.aws, {})
  azure            = try(var.object_storage.azure, {})
  gcp              = try(var.object_storage.gcp, {})
  byo              = try(var.object_storage.byo, null)
}

module "metrics_logs" {
  source = "./deps/metrics_logs"

  mode                     = try(var.metrics_logs.mode, "k8s")
  namespace                = local.namespaces.metrics_logs
  manage_namespace         = false
  kp_stack_chart_version   = try(var.metrics_logs.k8s.kp_stack_chart_version, null)
  loki_stack_chart_version = try(var.metrics_logs.k8s.loki_stack_chart_version, null)
  release_name_kps         = try(var.metrics_logs.k8s.release_name_kps, null)
  release_name_loki        = try(var.metrics_logs.k8s.release_name_loki, null)
  values                   = try(var.metrics_logs.k8s.values, {})

  depends_on = [kubernetes_namespace.deps]
}

module "oauth" {
  count  = local.oauth_enabled ? 1 : 0
  source = "./deps/oauth"

  mode             = try(var.oauth.mode, "k8s")
  namespace        = local.namespaces.oauth
  manage_namespace = false
  base_domain      = var.base_domain
  k8s              = try(var.oauth.k8s, {})
  aws              = try(var.oauth.aws, {})
  azure            = try(var.oauth.azure, {})
  gcp              = try(var.oauth.gcp, {})
  byo              = try(var.oauth.byo, null)

  depends_on = [module.ingress_tls]
}

module "secrets" {
  source = "./deps/secrets"

  mode             = try(var.secrets.mode, "k8s")
  namespace        = local.namespaces.secrets
  manage_namespace = false
  k8s              = try(var.secrets.k8s, {})
  aws              = try(var.secrets.aws, {})
  azure            = try(var.secrets.azure, {})
  gcp              = try(var.secrets.gcp, {})
  byo              = try(var.secrets.byo, null)
}

# BTP Platform module - deploys the SettleMint Helm chart
# Dynamically injects dependency connection details (postgres, redis, s3, vault, oauth)
# Works across all cloud providers (aws/azure/gcp/k8s/byo) without code changes
module "btp" {
  count  = var.btp.enabled ? 1 : 0
  source = "./btp"

  chart            = var.btp.chart
  chart_version    = var.btp.chart_version
  namespace        = var.btp.namespace
  release_name     = var.btp.release_name
  values           = var.btp.values
  values_file      = var.btp.values_file
  create_namespace = true

  base_domain = var.base_domain

  # Pass normalized dependency outputs (works for all modes: aws/azure/gcp/k8s/byo)
  postgres       = module.postgres
  redis          = module.redis
  object_storage = module.object_storage
  oauth          = local.oauth_outputs
  secrets        = module.secrets
  ingress_tls    = module.ingress_tls
  metrics_logs   = module.metrics_logs

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

  depends_on = [
    module.postgres,
    module.redis,
    module.object_storage,
    module.secrets,
    module.ingress_tls,
    module.metrics_logs
  ]
}
