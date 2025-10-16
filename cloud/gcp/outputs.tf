output "network" {
  description = "Computed GCP network values (placeholder)."
  value       = local.network
}

output "security_groups" {
  description = "Firewall/security constructs provisioned for shared dependencies (placeholder)."
  value       = local.security_groups
}

output "k8s_context" {
  description = "Network context consumed by the Kubernetes cluster module (placeholder)."
  value       = local.k8s_context
}

output "dependency_context" {
  description = "Pre-packaged network context for dependency modules (placeholder)."
  value       = local.dependency_context
}
