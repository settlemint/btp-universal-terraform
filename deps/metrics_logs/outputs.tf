output "prometheus_endpoint" {
  value = local.prometheus_url
}

output "loki_endpoint" {
  value = local.loki_url
}

output "grafana_url" {
  value = local.grafana_url
}

output "grafana_username" {
  value = "admin"
}

output "grafana_password" {
  value     = var.grafana_password
  sensitive = true
}
