output "host" {
  value = local.host
}

output "port" {
  value = local.port
}

output "username" {
  value = local.user
}

output "password" {
  value     = random_password.postgres.result
  sensitive = true
}

output "database" {
  value = var.database
}

output "connection_string" {
  value     = "postgres://${local.user}:${random_password.postgres.result}@${local.host}:${local.port}/${var.database}?sslmode=disable"
  sensitive = true
}

