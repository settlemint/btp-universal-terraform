# Runbook — Backup & Restore

Summary: Back up and restore stateful services (DB, object storage) safely.

Postgres
- Managed: use provider snapshots; document schedules and retention.
- k8s: pg_dump/pg_restore and PVC snapshots.

Object Storage
- Versioning and lifecycle policies; cross-region replication if needed.

