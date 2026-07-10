#!/usr/bin/env bash
# ==============================================================================
# 08-create-sample-db.sh
# Creates and seeds the retail sample database inside Spanner Omni on GKE.
# Runs administrative commands via kubectl exec for container-native execution.
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

NAMESPACE="spanner-omni"
DB_NAME="retail"

# 1. Resolve Pod Name
log_info "Resolving Spanner Omni pod name..."
POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=spanner-omni -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)

if [ -z "$POD_NAME" ]; then
    log_error "No Spanner Omni pods found in namespace $NAMESPACE. Make sure GKE cluster and Spanner Omni are deployed."
    exit 1
fi
log_success "Targeting pod: $POD_NAME"

# 2. Check if database already exists
log_info "Checking if database '$DB_NAME' already exists..."
DB_LIST=$(kubectl exec -n "$NAMESPACE" "pod/$POD_NAME" -- /google/spanner/bin/spanner databases list 2>/dev/null || true)

if echo "$DB_LIST" | grep -q "$DB_NAME"; then
    log_warning "Database '$DB_NAME' already exists. Skipping database seeding."
else
    log_info "Database '$DB_NAME' not found. Creating and seeding the Retail sample database..."
    # Execute the built-in Spanner Omni sample seeder tool
    kubectl exec -i -n "$NAMESPACE" "pod/$POD_NAME" -- \
        /google/spanner/bin/spanner databases create-sample-db retail --database-name="$DB_NAME"
        
    log_success "Successfully created and seeded Retail sample database: $DB_NAME"
fi

# 3. Verify database listing
log_info "Listing current Spanner Omni databases..."
echo "--------------------------------------------------"
kubectl exec -n "$NAMESPACE" "pod/$POD_NAME" -- /google/spanner/bin/spanner databases list
echo "--------------------------------------------------"

log_success "Database creation and seeding phase completed!"
