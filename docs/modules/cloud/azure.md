# Cloud — Azure

Summary
- Azure mapping for network, identity, Kubernetes (AKS), and managed services: PG Flexible Server, Azure Cache, Blob, Entra ID, Key Vault, App Gateway, Log Analytics/Managed Grafana.

Modes at a glance
- managed: Provision Azure-native resources and export unified outputs
- k8s: Deploy Helm charts into AKS
- byo: Consume pre-existing endpoints/credentials

Architecture notes
- Use private endpoints; Azure CNI; AGIC for ingress with Key Vault certs; Workload Identity for pods

Example profile (all managed)
```hcl
platform = "azure"
postgres = { mode = "managed", managed = { provider = "azure", sku = "B_Standard_B2s" } }
redis    = { mode = "managed", managed = { provider = "azure", sku = "Basic", capacity = 1 } }
object_storage = { mode = "managed", managed = { provider = "azure", account_name = "btpartifacts", container = "btp" } }
oauth    = { mode = "managed", managed = { provider = "azure", app_name = "btp" } }
secrets  = { mode = "managed", managed = { provider = "azure", vault_name = "btp-kv" } }
ingress_tls = { mode = "managed", managed = { provider = "azure", certificate = { key_vault_secret_id = "..." } } }
metrics_logs = { mode = "managed", managed = { provider = "azure", log_analytics = true } }
```

Verification
- Validate DNS and App Gateway listeners; confirm certs in Key Vault and bindings

Security & gotchas
- Use RBAC (not access policies) for KV where possible; scope Managed Identity access strictly

See also
- IAM reference: docs/reference/iam/azure.md
