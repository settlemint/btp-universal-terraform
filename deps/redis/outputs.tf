output "host" {
  value = local.host
}

output "port" {
  value = local.port
}

output "password" {
  value     = random_password.redis.result
  sensitive = true
}

output "scheme" {
  value = "redis"
}

output "tls_enabled" {
  value = false
}

