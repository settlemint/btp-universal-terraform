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

  ingress_tls_acme_explicit_raw = try(trimspace(var.ingress_tls.k8s.acme_email), "")
  ingress_tls_acme_explicit     = length(local.ingress_tls_acme_explicit_raw) > 0 ? local.ingress_tls_acme_explicit_raw : null
  ingress_tls_acme_is_placeholder = (
    local.ingress_tls_acme_explicit != null ?
    can(regex("example\\.com$", lower(local.ingress_tls_acme_explicit))) :
    false
  )

  ingress_tls_acme_candidates = compact([
    !local.ingress_tls_acme_is_placeholder ? local.ingress_tls_acme_explicit : null,
    try(trimspace(var.license_email), "") != "" ? try(trimspace(var.license_email), "") : null
  ])

  ingress_tls_acme_email = length(local.ingress_tls_acme_candidates) > 0 ? local.ingress_tls_acme_candidates[0] : null

  ingress_tls_wildcard_hosts = compact([
    try(module.dns.wildcard_hostname, null)
  ])

  ingress_tls_default_certificate = length(local.ingress_tls_wildcard_hosts) > 0 ? {
    enabled     = true
    secret_name = format("%s-wildcard", replace(var.base_domain, ".", "-"))
    hosts       = concat(local.ingress_tls_wildcard_hosts, [module.dns.hostname])
  } : null
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

resource "null_resource" "cleanup_k8s_cni_enis" {
  count = contains(["aws"], try(var.k8s_cluster.mode, "disabled")) ? 1 : 0

  triggers = {
    cluster_name = try(var.k8s_cluster.aws.cluster_name, "")
    vpc_id       = module.vpc.vpc_id
    region = coalesce(
      try(var.k8s_cluster.aws.region, null),
      try(var.vpc.aws.region, null),
      "us-east-1"
    )
  }

  provisioner "local-exec" {
    when       = destroy
    on_failure = continue
    command    = <<-EOT
      set -euo pipefail
      export AWS_REGION="${self.triggers.region}"
      CLUSTER="${self.triggers.cluster_name}"
      VPC_ID="${self.triggers.vpc_id}"

      if [ -z "$CLUSTER" ] || [ -z "$VPC_ID" ]; then
        exit 0
      fi

      echo "🔍 Checking for residual ENIs in VPC $VPC_ID for cluster $CLUSTER"
      for _ in $(seq 1 6); do
        ENIS=$(aws ec2 describe-network-interfaces \
          --filters "Name=tag:cluster.k8s.amazonaws.com/name,Values=$CLUSTER" "Name=vpc-id,Values=$VPC_ID" \
          --query 'NetworkInterfaces[].NetworkInterfaceId' --output text || echo "")

        if [ -z "$ENIS" ] || [ "$ENIS" = "None" ]; then
          echo "✅ No residual ENIs detected"
          exit 0
        fi

        for ENI in $ENIS; do
          echo "🧹 Deleting ENI $ENI"
          aws ec2 delete-network-interface --network-interface-id "$ENI" || true
        done

        sleep 10
      done

      echo "⚠️ Some ENIs may remain; please verify manually."
    EOT
  }

  depends_on = [module.k8s_cluster]
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

  # Pass Route53 zone ID for DNS-01 challenges when using AWS DNS
  route53_zone_id                 = module.dns.route53_zone_id
  aws_region                      = try(var.object_storage.region, "eu-central-1")
  route53_credentials_secret_name = try(var.ingress_tls.k8s.route53_credentials_secret_name, null)
  aws_access_key_id               = var.aws_access_key_id
  aws_secret_access_key           = var.aws_secret_access_key
  acme_email                      = local.ingress_tls_acme_email
  default_certificate             = local.ingress_tls_default_certificate

  depends_on = [kubernetes_namespace.deps, module.dns]
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
      password           = var.postgres_password
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
  base_domain      = var.base_domain
  k8s              = try(var.object_storage.k8s, {})
  aws              = try(var.object_storage.aws, {})
  azure            = try(var.object_storage.azure, {})
  gcp              = try(var.object_storage.gcp, {})
  byo              = try(var.object_storage.byo, null)
}

module "dns" {
  source = "./deps/dns"

  mode                    = try(var.dns.mode, "byo")
  domain                  = coalesce(try(var.dns.domain, null), var.base_domain)
  release_name            = var.btp.release_name
  enable_wildcard         = try(var.dns.enable_wildcard, true)
  include_wildcard_in_tls = coalesce(try(var.dns.include_wildcard_in_tls, null), try(var.dns.enable_wildcard, false), false)
  cert_manager_issuer     = try(var.dns.cert_manager_issuer, null)
  tls_secret_name         = try(var.dns.tls_secret_name, null)
  ssl_redirect            = try(var.dns.ssl_redirect, true)
  annotations             = try(var.dns.annotations, {})
  aws                     = try(var.dns.aws, null)
  azure                   = try(var.dns.azure, null)
  gcp                     = try(var.dns.gcp, null)
  cf                      = try(var.dns.cf, null)
  byo                     = try(var.dns.byo, null)
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

  chart                = var.btp.chart
  chart_version        = var.btp.chart_version
  namespace            = var.btp.namespace
  deployment_namespace = var.btp.deployment_namespace
  release_name         = var.btp.release_name
  values               = var.btp.values
  values_file          = var.btp.values_file
  create_namespace     = true

  base_domain = var.base_domain

  # Pass normalized dependency outputs (works for all modes: aws/azure/gcp/k8s/byo)
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

  # Google OAuth (temporary - for AWS + Google auth setup)
  google_oauth_client_id     = var.google_oauth_client_id
  google_oauth_client_secret = var.google_oauth_client_secret

  # Grafana admin password
  grafana_admin_password = var.grafana_admin_password

  depends_on = [
    module.postgres,
    module.redis,
    module.object_storage,
    module.secrets,
    module.ingress_tls,
    module.metrics_logs,
    module.dns
  ]
}
