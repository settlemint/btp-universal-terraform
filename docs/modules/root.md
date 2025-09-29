# Root Module

Purpose
- Orchestrates cluster namespaces, dependency modules under `deps/*`, and optionally deploys the BTP Helm release under `/btp`.
- Emits a stable, unified output contract consumed by `/btp` and your tooling.

Key Inputs
- `platform` (string): `aws | azure | gcp | generic` used for labeling and provider-specific defaults.
- `base_domain` (string): base DNS domain; local default `127.0.0.1.nip.io`.
- `cluster` (object): cluster creation/connection fields; `create`, `name`, `version`, `region`, `node_groups`, `kubeconfig_path`.
- `namespaces` (object): per-dependency namespaces with default `btp-deps`.
- Dependency blocks (objects): `postgres`, `redis`, `object_storage`, `ingress_tls`, `metrics_logs`, `oauth`, `secrets`.
  - Each has `mode` and a `k8s` sub-object (and conceptually `managed`/`byo` in universal usage).
- `btp` (object): enable and parameterize the SettleMint Helm release.
- Convenience secrets: `redis_password`, `object_storage_{access_key,secret_key}`, `grafana_admin_password`, `oauth_admin_password`, `secrets_dev_token`.
- License passthrough: `license_*` variables injected into the chart if present.

Outputs
- `postgres`: host, port, username, password, database, connection_string (sensitive).
- `redis`: host, port, password (sensitive), `scheme`, `tls_enabled`.
- `object_storage`: endpoint, bucket, access_key, secret_key, region, use_path_style (sensitive).
- `oauth`: issuer, admin_url, client_id, client_secret, scopes, callback_urls (sensitive).
- `secrets`: vault_addr, token, kv_mount, paths (sensitive token).
- `ingress_tls`: ingress_class, issuer_name.
- `metrics_logs`: prometheus_endpoint, loki_endpoint, grafana_url, grafana_username, grafana_password (sensitive).
- `btp`: helm release_name and namespace when enabled.

Mode Selection
- Each dependency accepts `mode = "managed" | "k8s" | "byo"`.
- In this repository, k8s mode is implemented for fast local/dev. Managed/BYO are documented across providers for universal usage.

Example tfvars (local)
```hcl
platform   = "generic"
base_domain = "127.0.0.1.nip.io"

postgres = {
  mode = "k8s"
  k8s = { database = "btp" }
}
redis = { mode = "k8s" }
object_storage = { mode = "k8s", k8s = { default_bucket = "btp-artifacts" } }
ingress_tls = { mode = "k8s" }
metrics_logs = { mode = "k8s" }
oauth = { mode = "k8s", k8s = { ingress_enabled = true } }
secrets = { mode = "k8s", k8s = { dev_mode = true } }

btp = { enabled = true }
```

See also
- Reference: `docs/reference/terraform/root.md` (generated)
- BTP wiring: `docs/modules/btp.md`
