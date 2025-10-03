output "host" {
  value = local.host
}

output "port" {
  value = local.port
}

output "password" {
  value     = coalesce(var.password, try(random_password.redis[0].result, null))
  sensitive = true
}

output "scheme" {
  value = "redis"
}

output "tls_enabled" {
  value = false
}
