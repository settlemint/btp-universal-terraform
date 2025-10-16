# GCP Provider Guide

## Status
Native GCP modules are not implemented yet. The GCP mode files inside each dependency act as placeholders so you can describe existing resources, but Terraform does not provision Google Cloud services today.

## Working with GCP today
- Use `mode = "byo"` to connect to Cloud SQL, Memorystore, GCS, Identity Platform, Secret Manager, or other existing services; provide endpoints and credentials via tfvars.
- Keep ingress, metrics/logs, and secrets in `k8s` mode (ingress-nginx, kube-prometheus-stack, Vault) until dedicated GCP integrations are added.
- Manage networking, service accounts, and DNS externally and feed the resulting values into root module inputs.

## Roadmap considerations
- When implementing GCP support, plan for Workload Identity, private service connectivity, and certificate automation so Kubernetes resources stay decoupled from service account keys.
- Document the required IAM roles and API enablement steps here once the modules land.
