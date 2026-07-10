#!/usr/bin/env bash
# ==============================================================================
# cleanup.sh
# Safely tears down the deployed GKE cluster and removes demo configuration files.
# ==============================================================================

set -euo pipefail

# ANSI color codes
RED='\033;31m'
GREEN='\033;32m'
YELLOW='\033;33m'
BLUE='\033;34m'
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
    log_error "Could not resolve a target project ID. Nothing to clean up."
    exit 0
fi

CLUSTER_NAME="spanner-omni-gke"
REGION="europe-west4"

# 2. Confirm Deletion
log_warning "=========================================================="
log_warning " WARNING: YOU ARE ABOUT TO DELETE THE FOLLOWING RESOURCES:"
log_warning "   - GKE Cluster: $CLUSTER_NAME (in region $REGION)"
log_warning "   - Namespace: spanner-omni and all running Spanner databases"
log_warning "   - Local configuration files and binaries"
log_warning "=========================================================="

read -p "Are you sure you want to proceed with deletion? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    log_info "Cleanup cancelled by user."
    exit 0
fi

# 3. Clean up port forwarding
log_info "Terminating background port-forwarding processes..."
pkill -f "port-forward.*15000" || true
pkill -f "port-forward.*15026" || true

# 4. Check if using Terraform or gcloud for cluster deletion
USE_TERRAFORM=${USE_TERRAFORM:-"false"}

if [ "$USE_TERRAFORM" == "true" ] && [ -d terraform ] && command -v terraform &>/dev/null; then
    log_info "Destroying GKE cluster and resources via Terraform..."
    cd terraform
    terraform destroy -var="project_id=$PROJECT_ID" -var="region=$REGION" -var="cluster_name=$CLUSTER_NAME" -auto-approve
    cd ..
    log_success "Terraform resources destroyed."
else
    log_info "Deleting GKE Cluster '$CLUSTER_NAME' via gcloud CLI (this may take 5-10 minutes)..."
    if gcloud container clusters describe "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID" &>/dev/null; then
        gcloud container clusters delete "$CLUSTER_NAME" \
            --region="$REGION" \
            --project="$PROJECT_ID" \
            --quiet
        log_success "GKE cluster deleted."
    else
        log_warning "GKE Cluster '$CLUSTER_NAME' not found in project $PROJECT_ID. Skipping cluster deletion."
    fi
fi

# 5. Clean up local files
log_info "Cleaning up local files and binaries..."
rm -f .gcp_project_id
rm -rf bin/

log_success "Cleanup completed successfully!"
