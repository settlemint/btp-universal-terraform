#!/usr/bin/env bash
set -euo pipefail

echo "[preflight] Checking kubectl and helm..."
command -v kubectl >/dev/null || { echo "kubectl not found"; exit 1; }
command -v helm >/dev/null || { echo "helm not found"; exit 1; }

echo "[preflight] Current context: $(kubectl config current-context)"
kubectl get nodes >/dev/null

echo "[preflight] Ensuring required Helm repos are present..."
helm repo add bitnami https://charts.bitnami.com/bitnami >/dev/null 2>&1 || true
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null 2>&1 || true
helm repo add jetstack https://charts.jetstack.io >/dev/null 2>&1 || true
helm repo add grafana https://grafana.github.io/helm-charts >/dev/null 2>&1 || true
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo add hashicorp https://helm.releases.hashicorp.com >/dev/null 2>&1 || true
helm repo add postgres-operator https://opensource.zalando.com/postgres-operator/charts/postgres-operator >/dev/null 2>&1 || true
helm repo update >/dev/null

# Optional: Login to OCI registry for SettleMint Platform if env vars are provided
REG_USER="${SETTLEMINT_REGISTRY_USERNAME:-${BTP_LICENSE_USERNAME:-}}"
REG_PASS="${SETTLEMINT_REGISTRY_PASSWORD:-${BTP_LICENSE_PASSWORD:-}}"
if [ -n "$REG_USER" ] && [ -n "$REG_PASS" ]; then
  # Determine registry host: prefer SETTLEMINT_REGISTRY; else try to parse from TF_VAR_btp_chart; else default to harbor
  REG_HOST="${SETTLEMINT_REGISTRY:-}"
  if [ -z "$REG_HOST" ] && [ -n "${TF_VAR_btp_chart:-}" ]; then
    REG_HOST=$(printf "%s" "$TF_VAR_btp_chart" | sed -E 's#^oci://([^/]+)/.*#\1#')
  fi
  if [ -z "$REG_HOST" ]; then
    REG_HOST="harbor.settlemint.com"
  fi
  MASK_USER="${REG_USER:0:2}***"
  echo "[preflight] Logging into OCI registry $REG_HOST as $MASK_USER"
  if echo "$REG_PASS" | helm registry login "$REG_HOST" --username "$REG_USER" --password-stdin >/dev/null 2>&1; then
    echo "[preflight] OCI login succeeded for $REG_HOST"
  else
    echo "[warn] Helm registry login failed for $REG_HOST" >&2
  fi
else
  echo "[warn] No registry credentials found in env (SETTLEMINT_REGISTRY_USERNAME/PASSWORD or BTP_LICENSE_USERNAME/PASSWORD). Skipping OCI login." >&2
fi

echo "[preflight] Checking default StorageClass..."
if ! kubectl get sc | grep -q "(default)"; then
  echo "Warning: No default StorageClass detected. Charts run with persistence disabled."
fi

echo "[preflight] OK"
