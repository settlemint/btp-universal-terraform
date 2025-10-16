output "host" {
  value = local.host
}

output "port" {
  value = local.port
}

output "password" {
  value     = local.password
  sensitive = true
}

output "scheme" {
  value = local.scheme
}

output "tls_enabled" {
  value = local.tls_enabled
}
