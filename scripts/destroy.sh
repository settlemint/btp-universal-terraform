#!/usr/bin/env bash
set -euo pipefail

VAR_FILE=${1:-examples/generic-orbstack-dev.tfvars}

echo "[destroy] Using var-file: ${VAR_FILE}"
if [ ! -f "$VAR_FILE" ]; then
  echo "[destroy] Var-file not found: $VAR_FILE" >&2
  echo "Usage: bash scripts/destroy.sh [path/to/vars.tfvars]" >&2
  exit 1
fi

echo "[destroy] Initializing Terraform..."
terraform init -upgrade

echo "[destroy] Destroying Terraform-managed resources..."
terraform destroy -auto-approve -var-file "$VAR_FILE"

echo "[destroy] Cleaning up any remaining namespaces..."
kubectl delete namespace btp-deps settlemint --ignore-not-found=true

echo "[destroy] Removing terraform state and cache files..."
rm -rf .terraform .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup

echo "[destroy] Reset complete! Ready for fresh deployment."

