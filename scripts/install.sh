#!/usr/bin/env bash
set -euo pipefail

VAR_FILE=${1:-examples/generic-orbstack-dev.tfvars}

echo "[install] Using var-file: ${VAR_FILE}"

if [ ! -f "$VAR_FILE" ]; then
  echo "[install] Var-file not found: $VAR_FILE" >&2
  echo "Usage: bash scripts/install.sh [path/to/vars.tfvars]" >&2
  exit 1
fi

echo "[install] Running preflight checks..."
bash "$(dirname "$0")/preflight.sh"

echo "[install] Initializing Terraform..."
terraform init

echo "[install] Validating Terraform..."
terraform validate

echo "[install] Applying Terraform (auto-approve)..."
terraform apply -auto-approve -var-file "$VAR_FILE"

echo "[install] Apply complete. Selected outputs (sensitive values hidden):"
terraform output || true

echo "[install] Done."
