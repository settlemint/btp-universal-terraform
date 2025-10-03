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
  value     = data.kubernetes_secret.postgres.data["password"]
  sensitive = true
}

output "database" {
  value = var.database
}

output "connection_string" {
  value     = "postgres://${local.user}:${data.kubernetes_secret.postgres.data["password"]}@${local.host}:${local.port}/${var.database}?sslmode=disable"
  sensitive = true
}
