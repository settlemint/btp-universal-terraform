# Unified Outputs Contract

All dependencies emit stable outputs consumed by `/btp` to configure the Helm release.
This enables swapping modes/providers without changing BTP values wiring.

Postgres
- `host`, `port`, `username`, `password` (sensitive), `database`
- `connection_string` (sensitive), optional `ssl_mode`

Redis
- `host`, `port`, `password` (sensitive), `scheme` (e.g., `redis`), `tls_enabled`

Object Storage
- `endpoint`, `bucket`, `access_key` (sensitive), `secret_key` (sensitive)
- `region`, `use_path_style`

OAuth
- `issuer`, `admin_url`
- Optional: `client_id`, `client_secret` (sensitive), `scopes`, `callback_urls`

Secrets
- `vault_addr`, `token` (sensitive, dev only), `kv_mount`, `paths`

Ingress/TLS
- `ingress_class`, `issuer_name` (or equivalent TLS config when managed/BYO)

Metrics/Logs
- `prometheus_endpoint`, `loki_endpoint`, `grafana_url`, `grafana_username`, `grafana_password` (sensitive)
