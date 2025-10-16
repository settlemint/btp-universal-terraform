output "endpoint" {
  value = local.endpoint
}

output "bucket" {
  value = local.bucket
}

output "access_key" {
  value     = local.access_key
  sensitive = true
}

output "secret_key" {
  value     = local.secret_key
  sensitive = true
}

output "region" {
  value = local.region
}

output "use_path_style" {
  value = local.use_path_style
}
