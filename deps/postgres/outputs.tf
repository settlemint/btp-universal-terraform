output "host" {
  value = local.host
}

output "port" {
  value = local.port
}

output "username" {
  value = local.username
}

output "password" {
  value     = local.password
  sensitive = true
}

output "database" {
  value = local.database
}

output "connection_string" {
  value     = local.connection_string
  sensitive = true
}
