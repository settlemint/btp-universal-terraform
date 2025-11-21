#!/bin/bash
set -e

# GCP Testing Script for BTP Universal Terraform
# This script guides you through testing the GCP/GKE implementation

COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_RED='\033[0;31m'
COLOR_BLUE='\033[0;34m'
COLOR_RESET='\033[0m'

echo -e "${COLOR_BLUE}╔════════════════════════════════════════════════════════════╗${COLOR_RESET}"
echo -e "${COLOR_BLUE}║  BTP Universal Terraform - GCP/GKE Testing Script         ║${COLOR_RESET}"
echo -e "${COLOR_BLUE}╚════════════════════════════════════════════════════════════╝${COLOR_RESET}"
echo ""

# Function to print section headers
print_section() {
    echo ""
    echo -e "${COLOR_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo -e "${COLOR_GREEN}  $1${COLOR_RESET}"
    echo -e "${COLOR_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo ""
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

print_section "Step 1: Prerequisites Check"

# Check for required tools
echo "Checking required tools..."
MISSING_TOOLS=()

if ! command_exists gcloud; then
    MISSING_TOOLS+=("gcloud")
fi
if ! command_exists terraform; then
    MISSING_TOOLS+=("terraform")
fi
if ! command_exists kubectl; then
    MISSING_TOOLS+=("kubectl")
fi

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    echo -e "${COLOR_RED}❌ Missing required tools: ${MISSING_TOOLS[*]}${COLOR_RESET}"
    echo ""
    echo "Install them with:"
    echo "  brew install google-cloud-sdk terraform kubernetes-cli"
    exit 1
else
    echo -e "${COLOR_GREEN}✅ All required tools are installed${COLOR_RESET}"
fi

print_section "Step 2: GCP Project Setup"

# Get current GCP project
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")

if [ -z "$CURRENT_PROJECT" ]; then
    echo -e "${COLOR_YELLOW}⚠️  No GCP project is currently set${COLOR_RESET}"
    echo ""
    read -p "Enter your GCP project ID: " PROJECT_ID
    gcloud config set project "$PROJECT_ID"
else
    echo -e "Current GCP project: ${COLOR_GREEN}$CURRENT_PROJECT${COLOR_RESET}"
    read -p "Use this project? (y/n): " USE_CURRENT
    if [[ $USE_CURRENT != "y" ]]; then
        read -p "Enter your GCP project ID: " PROJECT_ID
        gcloud config set project "$PROJECT_ID"
    else
        PROJECT_ID="$CURRENT_PROJECT"
    fi
fi

echo ""
echo -e "${COLOR_GREEN}✅ Using GCP project: $PROJECT_ID${COLOR_RESET}"

print_section "Step 3: Update Test Configuration"

# Update test-gcp.tfvars with the project ID
if [ -f "test-gcp.tfvars" ]; then
    echo "Updating test-gcp.tfvars with project ID..."
    sed -i.bak "s/YOUR_GCP_PROJECT_ID/$PROJECT_ID/g" test-gcp.tfvars
    rm test-gcp.tfvars.bak 2>/dev/null || true
    echo -e "${COLOR_GREEN}✅ Updated test-gcp.tfvars${COLOR_RESET}"
else
    echo -e "${COLOR_RED}❌ test-gcp.tfvars not found${COLOR_RESET}"
    exit 1
fi

print_section "Step 4: GCP Authentication"

echo "Checking GCP authentication..."
if gcloud auth application-default print-access-token >/dev/null 2>&1; then
    echo -e "${COLOR_GREEN}✅ Already authenticated with application-default credentials${COLOR_RESET}"
else
    echo -e "${COLOR_YELLOW}⚠️  Need to authenticate${COLOR_RESET}"
    echo "Running: gcloud auth application-default login"
    gcloud auth application-default login
fi

print_section "Step 5: Enable Required GCP APIs"

echo "Enabling required GCP APIs (this may take a few minutes)..."

APIS=(
    "container.googleapis.com"
    "compute.googleapis.com"
    "sqladmin.googleapis.com"
    "redis.googleapis.com"
    "storage.googleapis.com"
    "servicenetworking.googleapis.com"
)

for API in "${APIS[@]}"; do
    echo -n "  Enabling $API... "
    if gcloud services enable "$API" --project="$PROJECT_ID" 2>/dev/null; then
        echo -e "${COLOR_GREEN}✓${COLOR_RESET}"
    else
        echo -e "${COLOR_YELLOW}(already enabled or failed)${COLOR_RESET}"
    fi
done

echo ""
echo -e "${COLOR_GREEN}✅ APIs enabled${COLOR_RESET}"

print_section "Step 6: Verify Environment Variables"

# Check if .env exists
if [ ! -f ".env" ]; then
    echo -e "${COLOR_YELLOW}⚠️  .env file not found${COLOR_RESET}"
    echo "Creating .env from .env.example..."
    cp .env.example .env
    echo ""
    echo -e "${COLOR_YELLOW}⚠️  Please edit .env and set the following variables:${COLOR_RESET}"
    echo "  - TF_VAR_postgres_password"
    echo "  - TF_VAR_redis_password"
    echo "  - TF_VAR_grafana_admin_password"
    echo "  - TF_VAR_oauth_admin_password"
    echo "  - TF_VAR_jwt_signing_key"
    echo "  - TF_VAR_state_encryption_key"
    echo "  - TF_VAR_ipfs_cluster_secret"
    echo ""
    echo "Then re-run this script."
    exit 1
fi

echo "Loading environment variables from .env..."
set -a
source .env
set +a

# Check required variables
REQUIRED_VARS=(
    "TF_VAR_postgres_password"
    "TF_VAR_redis_password"
    "TF_VAR_grafana_admin_password"
    "TF_VAR_oauth_admin_password"
)

MISSING_VARS=()
for VAR in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!VAR}" ]; then
        MISSING_VARS+=("$VAR")
    fi
done

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo -e "${COLOR_RED}❌ Missing required environment variables:${COLOR_RESET}"
    for VAR in "${MISSING_VARS[@]}"; do
        echo "  - $VAR"
    done
    exit 1
else
    echo -e "${COLOR_GREEN}✅ All required environment variables are set${COLOR_RESET}"
fi

print_section "Step 7: Terraform Plan"

echo "Running terraform plan..."
echo ""

if terraform plan -var-file=test-gcp.tfvars -out=tfplan; then
    echo ""
    echo -e "${COLOR_GREEN}✅ Terraform plan succeeded!${COLOR_RESET}"
    echo ""
    echo -e "${COLOR_BLUE}Review the plan above. Key resources to be created:${COLOR_RESET}"
    echo "  - GKE cluster (btp-test-cluster)"
    echo "  - Cloud SQL PostgreSQL (btp-test-postgres)"
    echo "  - Memorystore Redis (btp-test-redis)"
    echo "  - Cloud Storage bucket (auto-generated name)"
    echo "  - Service accounts and IAM bindings"
    echo ""
else
    echo ""
    echo -e "${COLOR_RED}❌ Terraform plan failed${COLOR_RESET}"
    echo "Review the errors above and fix them before proceeding."
    exit 1
fi

print_section "Step 8: Deploy (Optional)"

echo -e "${COLOR_YELLOW}Ready to deploy?${COLOR_RESET}"
echo ""
echo "This will create:"
echo "  - GKE cluster (~10 minutes)"
echo "  - Cloud SQL instance (~5 minutes)"
echo "  - Memorystore Redis (~5 minutes)"
echo "  - Cloud Storage bucket (~1 minute)"
echo ""
echo "Estimated total time: ~15-20 minutes"
echo "Estimated monthly cost: ~\$150-200 (with BTP disabled)"
echo ""

read -p "Deploy now? (yes/no): " DEPLOY

if [[ $DEPLOY == "yes" ]]; then
    echo ""
    echo "Starting deployment..."
    echo ""

    if terraform apply tfplan; then
        echo ""
        echo -e "${COLOR_GREEN}╔════════════════════════════════════════════════════════════╗${COLOR_RESET}"
        echo -e "${COLOR_GREEN}║  ✅ Deployment Successful!                                 ║${COLOR_RESET}"
        echo -e "${COLOR_GREEN}╚════════════════════════════════════════════════════════════╝${COLOR_RESET}"
        echo ""
        echo "Next steps:"
        echo "  1. Configure kubectl:"
        echo "     gcloud container clusters get-credentials btp-test-cluster --region=us-central1 --project=$PROJECT_ID"
        echo ""
        echo "  2. Check cluster status:"
        echo "     kubectl get nodes"
        echo ""
        echo "  3. View deployed resources:"
        echo "     terraform output"
        echo ""
        echo "  4. Access Grafana (once ingress is ready):"
        echo "     kubectl get ingress -n btp-deps"
        echo ""
    else
        echo ""
        echo -e "${COLOR_RED}❌ Deployment failed${COLOR_RESET}"
        exit 1
    fi
else
    echo ""
    echo "Deployment skipped."
    echo ""
    echo "To deploy later, run:"
    echo "  terraform apply tfplan"
    echo ""
    echo "Or re-run this script."
fi

print_section "Testing Complete"

echo -e "${COLOR_GREEN}✅ All checks passed!${COLOR_RESET}"
echo ""
echo "To cleanup later, run:"
echo "  terraform destroy -var-file=test-gcp.tfvars"
