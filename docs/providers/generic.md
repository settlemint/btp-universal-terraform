# Generic Provider

**The generic profile runs all dependencies inside Kubernetes. Use this for local development or on-premises clusters.**

## Supported environments

- **Local** – OrbStack, kind, minikube
- **On-premises** – Bare metal or VM-based Kubernetes
- **Cloud Kubernetes** – When you manage the cluster yourself

No cloud scaffolding is provisioned.

## Prerequisites

**Kubernetes cluster with**
- Sufficient compute and storage
- Storage class supporting ReadWriteOnce (e.g., local-path provisioner)
- Ingress capabilities

**TLS support**
- cert-manager with self-signed or upstream issuer

## Kubernetes mode defaults

All dependencies run as Helm charts:
- **Postgres** – Zalando Operator with persistent volumes
- **Redis** – Bitnami chart with password auth
- **Object Storage** – MinIO with optional console
- **OAuth** – Keycloak
- **Secrets** – Vault (or Vault dev mode)
- **Ingress** – ingress-nginx + cert-manager
- **Observability** – kube-prometheus-stack + Loki

## Using bring-your-own endpoints

**Supply existing services**
- Set `mode = "byo"` for any dependency
- Provide connection details in tfvars
- Kubernetes services can still mount credentials via secrets

**For ingress**, point to an external load balancer or reverse proxy if TLS terminates elsewhere.
