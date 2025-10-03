output "vault_addr" {
  value = local.vault_addr
}

output "token" {
  value     = local.token
  sensitive = true
}

output "kv_mount" {
  value = local.kv_mount
}

output "paths" {
  value = local.paths
}
