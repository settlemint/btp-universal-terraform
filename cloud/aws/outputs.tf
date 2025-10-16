output "network" {
  description = "Computed AWS network values (VPC, subnets, NAT gateways)."
  value       = local.network
}

output "security_groups" {
  description = "Security groups provisioned for shared dependencies."
  value       = local.security_groups
}

output "k8s_context" {
  description = "Network context consumed by the Kubernetes cluster module."
  value       = local.k8s_context
}

output "dependency_context" {
  description = "Pre-packaged network context for dependency modules."
  value       = local.dependency_context
}
