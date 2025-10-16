# GCP GKE Cluster Implementation
# TODO: Implement full GCP GKE support when tackling GCP deployment

# Placeholder locals for outputs
locals {
  gcp_cluster_name     = var.mode == "gcp" ? "gcp-gke-placeholder" : null
  gcp_cluster_endpoint = var.mode == "gcp" ? "https://gcp-placeholder.example.com" : null
  gcp_cluster_ca_cert  = var.mode == "gcp" ? "" : null
  gcp_cluster_version  = var.mode == "gcp" ? "1.31" : null
  gcp_kubeconfig       = var.mode == "gcp" ? "" : null
}
