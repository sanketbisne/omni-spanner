#!/usr/bin/env bash
# ==============================================================================
# 03-enable-apis.sh
# Enables required Google Cloud Service APIs in the target project.
# ==============================================================================

set -euo pipefail

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 1. Resolve Project ID
PROJECT_ID=""
if [ -f .gcp_project_id ]; then
    PROJECT_ID=$(cat .gcp_project_id)
elif [ -n "${GCP_PROJECT_ID:-""}" ]; then
    PROJECT_ID=$GCP_PROJECT_ID
else
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null || true)
fi

if [ -z "$PROJECT_ID" ]; then
    log_error "No active Google Cloud Project resolved. Please run script '02-create-project.sh' first."
    exit 1
fi

log_info "Using project ID: $PROJECT_ID"

# 2. Define list of services to enable
SERVICES=(
    "serviceusage.googleapis.com"
    "cloudresourcemanager.googleapis.com"
    "container.googleapis.com"
    "compute.googleapis.com"
    "artifactregistry.googleapis.com"
    "iam.googleapis.com"
)

log_info "Enabling required Google Cloud APIs (this may take a minute)..."

# Enable services in batch
# Using gcloud services enable is idempotent and prints status
gcloud services enable "${SERVICES[@]}" --project="$PROJECT_ID"

# 3. Verify services are enabled
log_info "Verifying API activation status..."
ENABLED_SERVICES=$(gcloud services list --enabled --project="$PROJECT_ID" --format="value(config.name)")

MISSING=0
for service in "${SERVICES[@]}"; do
    if echo "$ENABLED_SERVICES" | grep -q "$service"; then
        log_success "API enabled: $service"
    else
        log_error "API failed to enable: $service"
        MISSING=1
    fi
done

if [ $MISSING -ne 0 ]; then
    log_error "Some service APIs failed to activate. Please check IAM permissions or Billing."
    exit 1
else
    log_success "All required Google Cloud APIs enabled successfully!"
fi
