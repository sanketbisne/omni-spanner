#!/usr/bin/env bash
# ==============================================================================
# 02-create-project.sh
# Verifies the active Google Cloud project or provisions a new one.
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

# 1. Determine Target Project ID
# Prioritize environment variable GCP_PROJECT_ID, fall back to argument, then interactive prompt, then current active config
PROJECT_ID=${GCP_PROJECT_ID:-${1:-""}}

if [ -z "$PROJECT_ID" ]; then
    log_info "No project ID supplied. Detecting current active gcloud configuration..."
    ACTIVE_CONFIG_PROJECT=$(gcloud config get-value project 2>/dev/null || true)
    if [ -n "$ACTIVE_CONFIG_PROJECT" ]; then
        PROJECT_ID=$ACTIVE_CONFIG_PROJECT
        log_info "Using active gcloud project: $PROJECT_ID"
    else
        log_error "No project ID specified. Set 'GCP_PROJECT_ID' or pass it as an argument."
        exit 1
    fi
fi

# 2. Check if project already exists
log_info "Verifying existence of project: $PROJECT_ID..."
if gcloud projects describe "$PROJECT_ID" &>/dev/null; then
    log_success "Project '$PROJECT_ID' already exists."
else
    log_info "Project '$PROJECT_ID' not found. Attempting to create it..."
    gcloud projects create "$PROJECT_ID" --name="Spanner Omni GKE Demo"
    log_success "Created new Google Cloud Project: $PROJECT_ID"
fi

# 3. Set config
log_info "Setting gcloud configuration project to: $PROJECT_ID..."
gcloud config set project "$PROJECT_ID"

# 4. Check Billing Account (Crucial for GKE and API activations)
log_info "Verifying billing status for project: $PROJECT_ID..."
BILLING_INFO=$(gcloud beta billing projects describe "$PROJECT_ID" --format="value(billingEnabled)" 2>/dev/null || true)

if [ "$BILLING_INFO" == "true" ]; then
    log_success "Billing is enabled on project '$PROJECT_ID'."
else
    log_warning "Billing is NOT enabled on project '$PROJECT_ID'."
    
    # Check if user provided billing account in env
    BILLING_ACCOUNT_ID=${GCP_BILLING_ACCOUNT_ID:-""}
    if [ -n "$BILLING_ACCOUNT_ID" ]; then
        log_info "Attempting to link billing account: $BILLING_ACCOUNT_ID..."
        gcloud beta billing projects link "$PROJECT_ID" --billing-account="$BILLING_ACCOUNT_ID"
        log_success "Linked billing account successfully."
    else
        log_warning "To deploy GKE, billing must be linked to project: $PROJECT_ID."
        log_warning "Please run: gcloud beta billing projects link $PROJECT_ID --billing-account=YOUR_ACCOUNT_ID"
        log_warning "Or set GCP_BILLING_ACCOUNT_ID env variable before running this script."
        log_warning "Proceeding anyway (assuming active billing in sandbox environment)..."
    fi
fi

log_success "Project configuration completed successfully!"
echo "$PROJECT_ID" > .gcp_project_id # Write to temp file for downstream script use
