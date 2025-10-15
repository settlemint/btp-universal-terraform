# Azure Provider Guide

## Status
Native Azure modules are not implemented yet. The Azure mode files under each dependency are placeholders so you can describe connection details, but Terraform does not currently provision Azure resources.

## Working with Azure today
- Use `mode = "byo"` to connect to existing Azure services (Flexible Server, Cache for Redis, Blob Storage, Entra ID, Key Vault, etc.) and supply endpoints/credentials via tfvars.
- Keep ingress, metrics/logs, and secrets in `k8s` mode (ingress-nginx, kube-prometheus-stack, Vault) until Azure-specific integrations land.
- Manage Azure networking, identities, and DNS outside of this repository; feed the resulting values into the root module inputs.

## Roadmap considerations
- When adding Azure support, align with managed identities and private networking expectations in `cloud/azure`.
- Document any required roles or Azure CLI steps in this guide so teams can follow a consistent pattern.
