output "issuer" {
  value = local.issuer
}

output "admin_url" {
  value = local.admin_url
}

output "client_id" {
  value = local.client_id
}

output "client_secret" {
  value     = local.client_secret
  sensitive = true
}

output "scopes" {
  value = local.scopes
}

output "callback_urls" {
  value = local.callback_urls
}
