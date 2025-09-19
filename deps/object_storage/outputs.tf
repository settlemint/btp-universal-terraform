output "endpoint" {
  value = local.endpoint
}

output "bucket" {
  value = var.default_bucket
}

output "access_key" {
  value     = "minio"
  sensitive = true
}

output "secret_key" {
  value     = random_password.secret.result
  sensitive = true
}

output "region" {
  value = "us-east-1"
}

output "use_path_style" {
  value = true
}

