#!/usr/bin/env bash
set -euo pipefail

VAR_FILE=${1:-examples/k8s-config.tfvars}

echo "[install] Using var-file: ${VAR_FILE}"

if [ ! -f "$VAR_FILE" ]; then
  echo "[install] Var-file not found: $VAR_FILE" >&2
  echo "Usage: bash scripts/install.sh [path/to/config.tfvars]" >&2
  echo "" >&2
  echo "Available configs:" >&2
  echo "  examples/k8s-config.tfvars   - Kubernetes-native (Helm charts)" >&2
  echo "  examples/aws-config.tfvars   - AWS managed services" >&2
  echo "  examples/azure-config.tfvars - Azure managed services" >&2
  echo "  examples/gcp-config.tfvars   - GCP managed services" >&2
  exit 1
fi

# Load environment variables from .env file if it exists
ENV_FILE="${ENV_FILE:-.env}"
if [ -f "$ENV_FILE" ]; then
  echo "[install] Loading environment from: $ENV_FILE"
  # Check if we need to use 1Password to resolve references
  if grep -q "^[A-Z_]*=op://" "$ENV_FILE" 2>/dev/null; then
    if command -v op >/dev/null 2>&1; then
      echo "[install] Detected 1Password references in $ENV_FILE"
      # Export resolved values from 1Password
      eval "$(op run --env-file="$ENV_FILE" -- env | grep -E '^(SETTLEMINT_|BTP_|TF_VAR_)' | sed 's/^/export /')"
    else
      echo "[warn] 1Password CLI not found. Cannot resolve op:// references in $ENV_FILE" >&2
      echo "[warn] Install 1Password CLI and sign in, or replace op:// references with actual values" >&2
    fi
  else
    # Regular .env file without 1Password references
    set -a
    source "$ENV_FILE"
    set +a
  fi
fi

echo "[install] Running preflight checks..."
bash "$(dirname "$0")/preflight.sh"

echo "[install] Initializing Terraform (upgrade providers as needed)..."
terraform init -upgrade

echo "[install] Validating Terraform..."
terraform validate

# Map License env vars to TF_VAR_* so Terraform can inject them into chart values
# When running under 'op run', the BTP_* vars are already set in the environment
# We need to ensure they're exported as TF_VAR_* for Terraform to pick them up
if [ -n "${BTP_LICENSE_USERNAME:-}" ]; then
  export TF_VAR_license_username="${BTP_LICENSE_USERNAME}"
fi
if [ -n "${BTP_LICENSE_PASSWORD:-}" ]; then
  export TF_VAR_license_password="${BTP_LICENSE_PASSWORD}"
fi
if [ -n "${BTP_LICENSE_SIGNATURE:-}" ]; then
  export TF_VAR_license_signature="${BTP_LICENSE_SIGNATURE}"
fi
if [ -n "${BTP_LICENSE_EMAIL:-}" ]; then
  export TF_VAR_license_email="${BTP_LICENSE_EMAIL}"
fi
if [ -n "${BTP_LICENSE_EXPIRATION_DATE:-}" ]; then
  export TF_VAR_license_expiration_date="${BTP_LICENSE_EXPIRATION_DATE}"
fi

# Platform security secrets
if [ -n "${BTP_JWT_SIGNING_KEY:-}" ]; then
  export TF_VAR_jwt_signing_key="${BTP_JWT_SIGNING_KEY}"
fi
if [ -n "${BTP_IPFS_CLUSTER_SECRET:-}" ]; then
  export TF_VAR_ipfs_cluster_secret="${BTP_IPFS_CLUSTER_SECRET}"
fi
if [ -n "${BTP_STATE_ENCRYPTION_KEY:-}" ]; then
  export TF_VAR_state_encryption_key="${BTP_STATE_ENCRYPTION_KEY}"
fi
if [ -n "${BTP_AWS_ACCESS_KEY_ID:-}" ]; then
  export TF_VAR_aws_access_key_id="${BTP_AWS_ACCESS_KEY_ID}"
fi
if [ -n "${BTP_AWS_SECRET_ACCESS_KEY:-}" ]; then
  export TF_VAR_aws_secret_access_key="${BTP_AWS_SECRET_ACCESS_KEY}"
fi

# Debug: Verify the variables are set
if [ -n "${TF_VAR_license_username:-}" ]; then
  echo "[install] License credentials configured for user: ${TF_VAR_license_username:0:3}***"
else
  echo "[warn] No license credentials found. Image pull secrets will be empty!" >&2
fi

# If using an OCI chart, pull it locally so Terraform can install from a local archive (avoids auth issues in provider)
CHART_REF_DEFAULT="oci://harbor.settlemint.com/settlemint/settlemint"
CHART_REF="${BTP_CHART_REF:-${TF_VAR_btp_chart:-$CHART_REF_DEFAULT}}"
CHART_VERSION="${BTP_CHART_VERSION:-${TF_VAR_btp_chart_version:-v7.32.3}}"
if printf "%s" "$CHART_REF" | grep -q '^oci://'; then
  mkdir -p charts
  echo "[install] Pulling chart $CHART_REF@$CHART_VERSION to ./charts"
  if helm pull "$CHART_REF" --version "$CHART_VERSION" --destination charts >/dev/null 2>&1; then
    ARCHIVE=$(ls -1 charts | grep -E '\.(tgz|tar\.gz)$' | grep -i 'settlemint' | sort | tail -n1)
    if [ -n "$ARCHIVE" ]; then
      export TF_VAR_btp_chart="charts/$ARCHIVE"
      export TF_VAR_btp_chart_version=""
      echo "[install] Using local chart archive: $TF_VAR_btp_chart"
    fi
  else
    echo "[warn] Helm pull failed for $CHART_REF@$CHART_VERSION; falling back to remote chart reference" >&2
  fi
fi

# If a release with the same name already exists in the namespace, import it to state to avoid name reuse errors
BTP_NS="${BTP_NAMESPACE:-settlemint}"
BTP_RELEASE="${BTP_RELEASE_NAME:-settlemint-platform}"
if helm -n "$BTP_NS" status "$BTP_RELEASE" >/dev/null 2>&1; then
  if ! terraform state show 'module.btp[0].helm_release.btp' >/dev/null 2>&1; then
    echo "[install] Importing existing Helm release $BTP_NS/$BTP_RELEASE into Terraform state"
    terraform import 'module.btp[0].helm_release.btp' "$BTP_NS/$BTP_RELEASE" || true
  fi
fi

# Stage 1: ensure namespaces and cert-manager (CRDs) are installed first to avoid race creating ClusterIssuer
echo "[install] Applying staged Terraform targets (namespaces + cert-manager CRDs)..."
terraform apply -auto-approve -var-file "$VAR_FILE" \
  -target kubernetes_namespace.deps \
  -target module.ingress_tls.helm_release.cert_manager || true

# Wait for cert-manager CRDs to be registered with the API server
echo "[install] Waiting for cert-manager CRDs to register..."
for crd in clusterissuers.cert-manager.io issuers.cert-manager.io; do
  if ! kubectl get crd "$crd" >/dev/null 2>&1; then
    # attempt a timed wait if supported
    kubectl wait --for=condition=Established "crd/$crd" --timeout=180s >/dev/null 2>&1 || true
  fi
done

echo "[install] Applying Terraform (auto-approve)..."
terraform apply -auto-approve -var-file "$VAR_FILE"

echo "[install] Apply complete. Selected outputs (sensitive values hidden):"
terraform output || true

echo "[install] Done."
