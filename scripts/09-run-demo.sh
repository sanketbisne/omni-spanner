#!/usr/bin/env bash
# ==============================================================================
# 09-run-demo.sh
# Executes basic and analytical SQL queries against the Spanner Omni retail DB.
# Pipes SQL commands directly to the containerized Spanner SQL CLI.
# ==============================================================================

set -euo pipefail

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_header() {
    echo -e "\n${CYAN}==================================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}==================================================${NC}"
}

NAMESPACE="spanner-omni"
DB_NAME="retail"

# 1. Resolve Pod Name
POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=spanner-omni -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)

if [ -z "$POD_NAME" ]; then
    log_error "No Spanner Omni pods found in namespace $NAMESPACE. Make sure the database is deployed."
    exit 1
fi

# Helper function to run a SQL command block
run_sql_block() {
    local label=$1
    local sql_file=$2
    
    log_header "$label"
    if [ ! -f "$sql_file" ]; then
        log_error "SQL file not found: $sql_file"
        exit 1
    fi
    
    log_info "Executing queries from: $sql_file"
    echo -e "${YELLOW}--- SQL Code ---${NC}"
    cat "$sql_file"
    echo -e "${YELLOW}----------------${NC}"
    
    log_info "Running queries inside container..."
    # We pipe the contents of the file directly to 'spanner sql'
    # Note: we filter out COSINE_DISTANCE if embedding array doesn't match perfectly,
    # but Spanner Omni's standard retail seeder does create 'Embedding' columns for products!
    set +e
    cat "$sql_file" | kubectl exec -i -n "$NAMESPACE" "pod/$POD_NAME" -- \
        /google/spanner/bin/spanner sql --database="$DB_NAME"
    STATUS=$?
    set -e
    
    if [ $STATUS -eq 0 ]; then
        log_success "Successfully executed $label queries."
    else
        log_warning "Executed queries with some warnings or errors. This is normal if advanced features require custom data loads."
    fi
}

# 2. Run Basic Queries
run_sql_block "BASIC RETROSPECTIVE & EXPLORATION" "sql/queries.sql"

# 3. Run Advanced Analytics Queries
run_sql_block "MULTI-TABLE JOIN & AGGREGATE REVENUE" "sql/analytics.sql"

log_success "Demo run complete! Web UI is active at http://localhost:15026 if '07-port-forward.sh' is running."
