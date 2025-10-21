# Azure Provider

**Native Azure modules are not implemented yet. Use bring-your-own mode to connect existing Azure services.**

## Azure support is planned

When implemented, the `cloud/azure` module will provision:
- Virtual networks and managed identities
- Azure Database for PostgreSQL Flexible Server
- Azure Cache for Redis
- Blob Storage
- Entra ID (Azure AD)
- Key Vault

## Working with Azure today

**Use `mode = "byo"` for all dependencies**
- Provide endpoints and credentials in tfvars
- Keep ingress, metrics/logs, and secrets in `k8s` mode

**Manage outside Terraform**
- Networking, identities, DNS
- All Azure resources
- Feed resulting values into root module inputs

## Roadmap

When adding Azure support:
- Align with managed identities and private networking
- Document required roles and Azure CLI steps
- Follow consistent patterns with AWS implementation
