#!/usr/bin/env bash
set -euo pipefail

VAR_FILE=${1:-examples/generic-orbstack-dev.tfvars}

echo "[destroy] Using var-file: ${VAR_FILE}"
if [ ! -f "$VAR_FILE" ]; then
  echo "[destroy] Var-file not found: $VAR_FILE" >&2
  echo "Usage: bash scripts/destroy.sh [path/to/vars.tfvars]" >&2
  exit 1
fi

echo "[destroy] Destroying Terraform-managed resources..."
terraform destroy -auto-approve -var-file "$VAR_FILE"

echo "[destroy] Done."

