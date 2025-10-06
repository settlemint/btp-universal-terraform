# Azure AKS Cluster Implementation
# TODO: Implement full Azure AKS support when tackling Azure deployment

# Placeholder locals for outputs
locals {
  azure_cluster_name     = var.mode == "azure" ? "azure-aks-placeholder" : null
  azure_cluster_endpoint = var.mode == "azure" ? "https://azure-placeholder.example.com" : null
  azure_cluster_ca_cert  = var.mode == "azure" ? "" : null
  azure_cluster_version  = var.mode == "azure" ? "1.31" : null
  azure_kubeconfig       = var.mode == "azure" ? "" : null
}
