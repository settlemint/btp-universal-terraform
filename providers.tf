locals {
  k8s_mode = try(var.k8s_cluster.mode, "disabled")

  provider_usage = {
    aws = anytrue([
      var.platform == "aws",
      local.k8s_mode == "aws",
      try(var.postgres.mode, "") == "aws",
      try(var.redis.mode, "") == "aws",
      try(var.object_storage.mode, "") == "aws",
      try(var.oauth.mode, "") == "aws",
      try(var.secrets.mode, "") == "aws",
      try(var.metrics_logs.mode, "") == "aws",
      try(var.dns.mode, "byo") == "aws"
    ])
    azure = anytrue([
      var.platform == "azure",
      local.k8s_mode == "azure",
      try(var.postgres.mode, "") == "azure",
      try(var.redis.mode, "") == "azure",
      try(var.object_storage.mode, "") == "azure",
      try(var.oauth.mode, "") == "azure",
      try(var.secrets.mode, "") == "azure",
      try(var.metrics_logs.mode, "") == "azure",
      try(var.dns.mode, "byo") == "azure"
    ])
    gcp = anytrue([
      var.platform == "gcp",
      local.k8s_mode == "gcp",
      try(var.postgres.mode, "") == "gcp",
      try(var.redis.mode, "") == "gcp",
      try(var.object_storage.mode, "") == "gcp",
      try(var.oauth.mode, "") == "gcp",
      try(var.secrets.mode, "") == "gcp",
      try(var.metrics_logs.mode, "") == "gcp",
      try(var.dns.mode, "byo") == "gcp"
    ])
    cloudflare = try(var.dns.mode, "byo") == "cf"
  }
}

# AWS Provider - configured via environment variables or AWS credential chain
# Set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION in environment
# or use AWS CLI profiles, IAM roles, etc.
provider "aws" {
  # When no AWS-backed dependency is active, skip validation to avoid requiring credentials.
  skip_credentials_validation = !local.provider_usage.aws
  skip_metadata_api_check     = !local.provider_usage.aws
  skip_region_validation      = !local.provider_usage.aws
}

# Azure Provider - configured via environment variables or Azure CLI
provider "azurerm" {
  features {}

  # Only register providers when running an Azure-backed dependency.
  skip_provider_registration   = !local.provider_usage.azure
  disable_terraform_partner_id = !local.provider_usage.azure
}

# GCP Provider - configured via environment variables or gcloud CLI
provider "google" {
  # Project and region can be set via GOOGLE_PROJECT and GOOGLE_REGION env vars
  # or via gcloud CLI configuration
}

# Cloudflare provider is configured automatically when dns.mode = "cf" via environment variables.

# Write kubeconfig for managed clusters (AWS/Azure/GCP)
resource "local_file" "kubeconfig" {
  count    = module.k8s_cluster.write_kubeconfig ? 1 : 0
  content  = module.k8s_cluster.kubeconfig
  filename = module.k8s_cluster.kubeconfig_path

  depends_on = [module.k8s_cluster]
}

# Kubernetes Provider - uses dedicated kubeconfig file (never ~/.kube/config)
# Uses host/exec auth directly instead of kubeconfig file to avoid chicken-egg problem
provider "kubernetes" {
  host                   = try(module.k8s_cluster.cluster_endpoint, null)
  cluster_ca_certificate = try(base64decode(module.k8s_cluster.cluster_ca_certificate), null)

  dynamic "exec" {
    for_each = module.k8s_cluster.provider_exec
    content {
      api_version = exec.value.api_version
      command     = exec.value.command
      args        = exec.value.args
    }
  }

  # For BYO mode, use kubeconfig file
  config_path = module.k8s_cluster.write_kubeconfig ? null : module.k8s_cluster.kubeconfig_path
}

# Helm Provider - same approach
provider "helm" {
  kubernetes {
    host                   = try(module.k8s_cluster.cluster_endpoint, null)
    cluster_ca_certificate = try(base64decode(module.k8s_cluster.cluster_ca_certificate), null)

    dynamic "exec" {
      for_each = module.k8s_cluster.provider_exec
      content {
        api_version = exec.value.api_version
        command     = exec.value.command
        args        = exec.value.args
      }
    }

    # For BYO mode, use kubeconfig file
    config_path = module.k8s_cluster.write_kubeconfig ? null : module.k8s_cluster.kubeconfig_path
  }
}
