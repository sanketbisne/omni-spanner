#!/usr/bin/env bash
# ==============================================================================
# 04-create-gke.sh
# Creates GKE Standard cluster and configures local kubectl.
# Supports both Terraform and direct gcloud CLI modes.
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
    log_error "No active Google Cloud Project resolved. Run scripts '02-create-project.sh' and '03-enable-apis.sh' first."
    exit 1
fi

CLUSTER_NAME="spanner-omni-gke"
REGION="europe-west4"
MACHINE_TYPE="e2-standard-4"

# 2. Check deployment mode (Terraform vs gcloud CLI)
USE_TERRAFORM=${USE_TERRAFORM:-"false"}

if [ "$USE_TERRAFORM" == "true" ] && command -v terraform &>/dev/null; then
    log_info "Deploying GKE cluster via Terraform..."
    
    cd terraform
    log_info "Initializing Terraform..."
    terraform init
    
    log_info "Applying Terraform execution plan (this can take 5-10 minutes)..."
    terraform apply -var="project_id=$PROJECT_ID" -var="region=$REGION" -var="cluster_name=$CLUSTER_NAME" -var="machine_type=$MACHINE_TYPE" -auto-approve
    
    cd ..
    log_success "Terraform deployment completed successfully!"
else
    log_info "Deploying GKE cluster via gcloud CLI (this can take 5-10 minutes)..."
    
    # Check if cluster already exists to avoid error
    if gcloud container clusters describe "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID" &>/dev/null; then
        log_warning "GKE Cluster '$CLUSTER_NAME' already exists. Skipping creation."
    else
        # Create VPC-native regional cluster with e2-standard-4 machines
        gcloud container clusters create "$CLUSTER_NAME" \
            --project="$PROJECT_ID" \
            --region="$REGION" \
            --num-nodes=1 \
            --node-locations="${REGION}-a","${REGION}-b","${REGION}-c" \
            --machine-type="$MACHINE_TYPE" \
            --disk-size=100GB \
            --disk-type="pd-ssd" \
            --enable-ip-alias \
            --enable-autoscaling --min-nodes=1 --max-nodes=5 \
            --scopes="https://www.googleapis.com/auth/cloud-platform" \
            --async
            
        log_info "GKE cluster creation initiated in background. Polling cluster status..."
        
        # Poll cluster status until RUNNING
        while true; do
            STATUS=$(gcloud container clusters list --project="$PROJECT_ID" --filter="name=$CLUSTER_NAME" --format="value(status)" 2>/dev/null || true)
            if [ "$STATUS" == "RUNNING" ]; then
                log_success "GKE Cluster is running!"
                break
            elif [ "$STATUS" == "STOPPING" ] || [ "$STATUS" == "DEGRADED" ] || [ "$STATUS" == "ERROR" ]; then
                log_error "Cluster ended up in bad state: $STATUS"
                exit 1
            else
                log_info "Current cluster status: ${STATUS:-PROVISIONING}. Waiting 30s..."
                sleep 30
            fi
        done
    fi
fi

# 3. Configure kubectl connection credentials
log_info "Configuring kubectl credentials for cluster: $CLUSTER_NAME..."
gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID"

log_info "Verifying cluster connectivity..."
kubectl cluster-info

log_success "GKE cluster successfully deployed and configured!"
