#!/usr/bin/env bash
# ==============================================================================
# 01-prerequisites.sh
# Performs system diagnostic checks and validates local development environment.
# ==============================================================================

set -euo pipefail

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}
log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}
log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}
log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_info "Starting environment checks..."

FAILED=0

# Helper to check command existence
check_cmd() {
    local cmd=$1
    local install_msg=$2
    if command -v "$cmd" &>/dev/null; then
        log_success "Found CLI: $cmd"
    else
        log_error "Missing CLI: $cmd. $install_msg"
        FAILED=1
    fi
}

# 1. Validate commands
check_cmd "gcloud" "Install Google Cloud SDK from https://cloud.google.com/sdk"
check_cmd "kubectl" "Install using: gcloud components install kubectl"
check_cmd "helm" "Install using: brew install helm"
check_cmd "docker" "Ensure Docker Desktop or daemon is running. Download from https://www.docker.com"
check_cmd "git" "Install using: brew install git"
check_cmd "jq" "Install using: brew install jq"
check_cmd "yq" "Install using: brew install yq"

# 2. Check gcloud auth
if command -v gcloud &>/dev/null; then
    log_info "Checking Google Cloud Authentication status..."
    ACTIVE_ACCOUNT=$(gcloud auth list --filter=status=ACTIVE --format="value(account)" 2>/dev/null || true)
    if [ -z "$ACTIVE_ACCOUNT" ]; then
        log_error "No active Google Cloud account found. Run: gcloud auth login"
        FAILED=1
    else
        log_success "Active GCP Account: $ACTIVE_ACCOUNT"
    fi
fi

# 3. Check Docker Daemon connection
if command -v docker &>/dev/null; then
    log_info "Checking Docker Daemon connection..."
    if docker info &>/dev/null; then
        log_success "Docker Daemon is running and responsive."
    else
        log_warning "Docker daemon is not running or current user lacks access. Please start Docker."
        # We don't fail immediately, as user might run Terraform/GKE without local docker,
        # but docker is required for some advanced local operations.
    fi
fi

if [ $FAILED -ne 0 ]; then
    log_error "Prerequisite check failed! Please install missing tools and re-run."
    exit 1
else
    log_success "All critical prerequisite checks passed! You are ready to deploy."
fi
