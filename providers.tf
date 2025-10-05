locals {
  kubeconfig_path = coalesce(try(var.cluster.kubeconfig_path, null), pathexpand("~/.kube/config"))
}

# AWS Provider - configured via environment variables or AWS credential chain
# Set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION in environment
# or use AWS CLI profiles, IAM roles, etc.
provider "aws" {
  # Region can be overridden via AWS_REGION env var or aws_config blocks in modules
  # For multi-region setups, modules can use provider aliases
}

provider "kubernetes" {
  config_path = local.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = local.kubeconfig_path
  }
}
