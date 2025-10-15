locals {
  # Dedicated kubeconfig file path for each mode
  # For AWS/Azure/GCP: Write kubeconfig from module output to dedicated file
  # For BYO: Use explicit path from config (required)
  k8s_mode = try(var.k8s_cluster.mode, "disabled")

  kubeconfig_path_map = {
    byo   = try(pathexpand(var.k8s_cluster.byo.kubeconfig_path), null)
    aws   = "${path.root}/.terraform/kubeconfig-aws"
    azure = "${path.root}/.terraform/kubeconfig-azure"
    gcp   = "${path.root}/.terraform/kubeconfig-gcp"
  }

  kubeconfig_path = lookup(local.kubeconfig_path_map, local.k8s_mode, null)

  # AWS EKS exec configuration for kubernetes and helm providers
  aws_exec_config = local.k8s_mode == "aws" ? [{
    api_version = "client.authentication.k8s.io/v1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      var.k8s_cluster.aws.cluster_name,
      "--region",
      var.k8s_cluster.aws.region
    ]
  }] : []

  provider_usage = {
    aws = anytrue([
      var.platform == "aws",
      try(var.k8s_cluster.mode, "") == "aws",
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
      try(var.k8s_cluster.mode, "") == "azure",
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
      try(var.k8s_cluster.mode, "") == "gcp",
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
  count    = contains(["aws", "azure", "gcp"], try(var.k8s_cluster.mode, "disabled")) ? 1 : 0
  content  = module.k8s_cluster.kubeconfig
  filename = local.kubeconfig_path

  depends_on = [module.k8s_cluster]
}

# Kubernetes Provider - uses dedicated kubeconfig file (never ~/.kube/config)
# Uses host/exec auth directly instead of kubeconfig file to avoid chicken-egg problem
provider "kubernetes" {
  host                   = try(module.k8s_cluster.cluster_endpoint, null)
  cluster_ca_certificate = try(base64decode(module.k8s_cluster.cluster_ca_certificate), null)

  dynamic "exec" {
    for_each = local.aws_exec_config
    content {
      api_version = exec.value.api_version
      command     = exec.value.command
      args        = exec.value.args
    }
  }

  # For BYO mode, use kubeconfig file
  config_path = local.k8s_mode == "byo" ? local.kubeconfig_path : null
}

# Helm Provider - same approach
provider "helm" {
  kubernetes {
    host                   = try(module.k8s_cluster.cluster_endpoint, null)
    cluster_ca_certificate = try(base64decode(module.k8s_cluster.cluster_ca_certificate), null)

    dynamic "exec" {
      for_each = local.aws_exec_config
      content {
        api_version = exec.value.api_version
        command     = exec.value.command
        args        = exec.value.args
      }
    }

    # For BYO mode, use kubeconfig file
    config_path = local.k8s_mode == "byo" ? local.kubeconfig_path : null
  }
}
