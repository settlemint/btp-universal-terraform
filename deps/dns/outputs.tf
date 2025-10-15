output "hostname" {
  description = "Primary ingress hostname for the platform"
  value       = var.domain
}

output "wildcard_hostname" {
  description = "Wildcard hostname (*.domain) when enabled"
  value       = local.wildcard_hostname
}

output "tls_secret_name" {
  description = "TLS secret name to reference in ingress resources"
  value       = local.tls_secret_name
}

output "tls_hosts" {
  description = "TLS host list for ingress resources"
  value       = local.tls_hosts
}

output "ingress_annotations" {
  description = "Ingress annotations merged from DNS automation"
  value       = local.ingress_annotations
}

output "ssl_redirect" {
  description = "Whether SSL redirect should be enabled on the ingress"
  value       = local.ssl_redirect
}

output "records" {
  description = "DNS records managed by this module (for visibility)"
  value       = local.records

  precondition {
    condition     = !local.unsupported_mode
    error_message = format("dns.mode '%s' is not yet implemented. Supported modes: aws, byo.", var.mode)
  }

  precondition {
    condition     = local.aws_zone_valid
    error_message = "When dns.mode is 'aws', set dns.aws.zone_id or dns.aws.zone_name."
  }
}

output "route53_zone_id" {
  description = "AWS Route53 hosted zone ID (null for non-AWS modes)"
  value       = local.aws_zone_id
}
