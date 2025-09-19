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
helm repo update >/dev/null

echo "[preflight] Checking default StorageClass..."
if ! kubectl get sc | grep -q "(default)"; then
  echo "Warning: No default StorageClass detected. Charts run with persistence disabled."
fi

echo "[preflight] OK"

