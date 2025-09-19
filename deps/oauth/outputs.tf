output "issuer" {
  value = local.issuer_url
}

output "admin_url" {
  value = local.http_url
}

output "client_id" {
  value = null
}

output "client_secret" {
  value     = null
  sensitive = true
}

output "scopes" {
  value = []
}

output "callback_urls" {
  value = []
}

