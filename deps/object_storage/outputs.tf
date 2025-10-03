output "endpoint" {
  value = local.endpoint
}

output "bucket" {
  value = var.default_bucket
}

output "access_key" {
  value     = coalesce(var.access_key, "minio")
  sensitive = true
}

output "secret_key" {
  value     = coalesce(var.secret_key, try(random_password.secret[0].result, null))
  sensitive = true
}

output "region" {
  value = "us-east-1"
}

output "use_path_style" {
  value = true
}
