#!/usr/bin/env bash
# ==============================================================================
# 07-port-forward.sh
# Establishes local background port-forwarding to GKE for database and web console.
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

# 1. Verify services exist
log_info "Verifying services exist..."
if ! kubectl get service spanner -n "$NAMESPACE" &>/dev/null; then
    log_error "Service 'spanner' not found in namespace $NAMESPACE."
    exit 1
fi
if ! kubectl get service spanner-omni-console -n "$NAMESPACE" &>/dev/null; then
    log_error "Service 'spanner-omni-console' not found in namespace $NAMESPACE."
    exit 1
fi

# 2. Terminate existing port-forwards to prevent address collision
log_info "Cleaning up existing port-forward processes on ports 15000 or 15026..."
# Kill any processes running kubectl port-forward for these ports
pkill -f "port-forward.*15000" || true
pkill -f "port-forward.*15026" || true
sleep 1

# 3. Launch port-forwarding in the background
log_info "Starting port-forwarding (15000: Database service, 15026: Console UI service)..."
nohup kubectl port-forward -n "$NAMESPACE" service/spanner 15000:15000 > /tmp/spanner_db_portforward.log 2>&1 &
nohup kubectl port-forward -n "$NAMESPACE" service/spanner-omni-console 15026:15026 > /tmp/spanner_ui_portforward.log 2>&1 &

# 4. Wait for ports to become active
log_info "Waiting for ports to open..."
MAX_ATTEMPTS=15
ATTEMPT=0
SUCCESS=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if curl -s -I http://localhost:15026 &>/dev/null || nc -z localhost 15000 &>/dev/null; then
        SUCCESS=1
        break
    fi
    ATTEMPT=$((ATTEMPT + 1))
    log_info "Polling localhost:15026 and localhost:15000 ($ATTEMPT/$MAX_ATTEMPTS)..."
    sleep 2
done

if [ $SUCCESS -eq 1 ]; then
    log_success "Port-forwarding established successfully!"
    log_success "--------------------------------------------------------"
    log_success "  ► Database Endpoint: localhost:15000"
    log_success "  ► Web Console UI:    http://localhost:15026"
    log_success "--------------------------------------------------------"
    log_info "Port forwarding logs: /tmp/spanner_db_portforward.log and /tmp/spanner_ui_portforward.log"
else
    log_error "Port-forwarding failed to establish. Check logs:"
    cat /tmp/spanner_db_portforward.log || true
    cat /tmp/spanner_ui_portforward.log || true
    exit 1
fi
