# Runbook — Switch Modes (k8s ↔ managed ↔ byo)

Summary: Migrate a dependency between modes with minimal downtime.

General Flow
1) Prepare target service (provision or validate BYO)
2) Enable dual-write/read or pause writes (as appropriate)
3) Migrate data (DB dump/restore, bucket sync, cache warm)
4) Flip mode in tfvars and `terraform apply`
5) Verify and decommission source

