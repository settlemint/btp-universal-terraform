output "ingress_class" {
  value = "nginx"
}

output "issuer_name" {
  value = var.issuer_name
}

locals {
  load_balancer_info = var.lookup_load_balancer ? merge(
    local.ingress_lb_hostname != null || local.ingress_lb_ip != null ? {
      hostname = local.ingress_lb_hostname
      ip       = local.ingress_lb_ip
    } : {},
    local.ingress_lb_dns_name != null ? {
      dns_name = local.ingress_lb_dns_name
    } : {},
    local.ingress_lb_zone_id != null ? {
      zone_id = local.ingress_lb_zone_id
    } : {}
  ) : {}
}

output "load_balancer" {
  description = "Resolved AWS load balancer details for ingress-nginx."
  value       = length(local.load_balancer_info) > 0 ? local.load_balancer_info : null
}
