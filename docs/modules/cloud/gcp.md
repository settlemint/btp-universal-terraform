# Cloud — GCP

Summary
- GCP mapping for network, identity, Kubernetes (GKE), and managed services: Cloud SQL, Memorystore, GCS, Identity Platform, Secret Manager, HTTPS LB + Managed Certs, Cloud Logging/Monitoring.

Modes at a glance
- managed: Provision GCP-native resources and export unified outputs
- k8s: Deploy Helm charts into GKE
- byo: Consume pre-existing endpoints/credentials

Architecture notes
- Prefer private GKE; Private Service Connect (PSC) for Cloud SQL; Workload Identity for k8s → GCP APIs

Example profile (all managed)
```hcl
platform = "gcp"
postgres = { mode = "managed", managed = { provider = "gcp", tier = "db-f1-micro" } }
redis    = { mode = "managed", managed = { provider = "gcp", tier = "BASIC" } }
object_storage = { mode = "managed", managed = { provider = "gcp", bucket = "btp-artifacts" } }
oauth    = { mode = "managed", managed = { provider = "gcp", app_name = "btp" } }
secrets  = { mode = "managed", managed = { provider = "gcp" } }
ingress_tls = { mode = "managed", managed = { provider = "gcp", managed_cert = true } }
metrics_logs = { mode = "managed", managed = { provider = "gcp", managed_prometheus = true } }
```

Verification
- Validate HTTPS LB and managed cert provisioning; confirm endpoints resolve

Security & gotchas
- Scope service accounts minimally; keep Cloud SQL access private via PSC

See also
- IAM reference: docs/reference/iam/gcp.md
