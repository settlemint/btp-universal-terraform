# Generic Provider Guide

## Scope
- The generic profile targets environments where you control the Kubernetes cluster directly (local OrbStack/kind/minikube or on-prem).
- No cloud scaffolding is provisioned; all dependencies default to Kubernetes mode unless overridden with `byo`.

## Prerequisites
- Accessible Kubernetes cluster with sufficient compute, storage, and ingress capabilities.
- Storage class that supports ReadWriteOnce (e.g., local-path provisioner, OrbStack’s default).
- TLS support via cert-manager (self-signed or upstream issuer).

## Kubernetes mode defaults
- Postgres via Zalando Operator with persistent volumes.
- Redis via Bitnami chart with password auth enabled.
- MinIO for object storage with optional console exposure.
- Keycloak for OAuth, Vault (or Vault dev) for secrets, ingress-nginx + cert-manager for edge routing, kube-prometheus-stack + Loki for observability.

## Bring-your-own tips
- Supply existing endpoints for any dependency using the `byo` mode configuration; Kubernetes services can still mount credentials via secrets.
- For ingress, point the BYO configuration to an external load balancer or reverse proxy and provide certificate references if TLS is terminated elsewhere.
