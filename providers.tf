locals {
  kubeconfig_path = coalesce(try(var.cluster.kubeconfig_path, null), pathexpand("~/.kube/config"))
}

provider "kubernetes" {
  config_path = local.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = local.kubeconfig_path
  }
}
