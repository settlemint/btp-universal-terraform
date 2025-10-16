# Unified outputs that work across all modes (aws, azure, gcp, byo, disabled)

output "cluster_name" {
  description = "Name of the Kubernetes cluster"
  value = coalesce(
    local.aws_cluster_name,
    local.azure_cluster_name,
    local.gcp_cluster_name,
    local.byo_cluster_name,
    "no-cluster"
  )
}

output "cluster_endpoint" {
  description = "Endpoint of the Kubernetes cluster API server"
  value = coalesce(
    local.aws_cluster_endpoint,
    local.azure_cluster_endpoint,
    local.gcp_cluster_endpoint,
    local.byo_cluster_endpoint,
    ""
  )
  sensitive = true
}

output "cluster_ca_certificate" {
  description = "Base64 encoded certificate data for the cluster CA"
  value = coalesce(
    local.aws_cluster_ca_cert,
    local.azure_cluster_ca_cert,
    local.gcp_cluster_ca_cert,
    local.byo_cluster_ca_cert,
    ""
  )
  sensitive = true
}

output "cluster_version" {
  description = "Kubernetes version of the cluster"
  value = coalesce(
    local.aws_cluster_version,
    local.azure_cluster_version,
    local.gcp_cluster_version,
    local.byo_cluster_version,
    "unknown"
  )
}

output "kubeconfig" {
  description = "Kubeconfig for accessing the cluster"
  value = coalesce(
    local.aws_kubeconfig,
    local.azure_kubeconfig,
    local.gcp_kubeconfig,
    local.byo_kubeconfig_output,
    ""
  )
  sensitive = true
}

output "kubeconfig_path" {
  description = "Filesystem path where the kubeconfig should be written or read from"
  value       = local.kubeconfig_path
}

output "write_kubeconfig" {
  description = "Indicates if Terraform should materialize the kubeconfig content to disk"
  value       = local.write_kubeconfig
}

output "provider_exec" {
  description = "Exec configuration for kubernetes/helm providers (primarily for AWS EKS)"
  value       = var.mode == "aws" ? local.aws_provider_exec : []
}

# AWS-specific outputs
output "aws_oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA (AWS only)"
  value       = local.aws_oidc_provider_arn
}

output "aws_oidc_provider_url" {
  description = "URL of the OIDC provider for IRSA (AWS only)"
  value       = local.aws_oidc_provider_url
}

output "aws_cluster_security_group_id" {
  description = "Security group ID for the EKS cluster (AWS only)"
  value       = var.mode == "aws" ? aws_security_group.eks_cluster[0].id : null
}

output "aws_node_group_role_arn" {
  description = "IAM role ARN for EKS node groups (AWS only)"
  value       = var.mode == "aws" ? aws_iam_role.eks_node_group[0].arn : null
}

# Azure-specific outputs
output "azure_cluster_id" {
  description = "Resource ID of the AKS cluster (Azure only)"
  value       = null # TODO: Implement when Azure AKS is added
}

output "azure_kubelet_identity" {
  description = "Kubelet identity for AKS (Azure only)"
  value       = null # TODO: Implement when Azure AKS is added
}

# GCP-specific outputs
output "gcp_cluster_id" {
  description = "Resource ID of the GKE cluster (GCP only)"
  value       = null # TODO: Implement when GCP GKE is added
}

output "gcp_cluster_location" {
  description = "Location of the GKE cluster (GCP only)"
  value       = null # TODO: Implement when GCP GKE is added
}

# Mode output
output "mode" {
  description = "Deployment mode for the cluster"
  value       = var.mode
}
