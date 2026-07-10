#!/usr/bin/env bash
# ==============================================================================
# 06-install-spanner-omni.sh
# Deploys Google Cloud Spanner Omni on GKE using Helm and sets up monitoring.
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
CHART_URL="oci://us-docker.pkg.dev/spanner-omni/charts/spanner-omni"
CHART_VERSION="0.2.0"
VALUES_FILE="manifests/spanner-values.yaml"

# 1. Create Namespace
log_info "Creating Kubernetes namespace: $NAMESPACE..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# 2. Deploy Spanner Omni via Helm
log_info "Deploying Spanner Omni (Chart version $CHART_VERSION) on GKE..."
if [ ! -f "$VALUES_FILE" ]; then
    log_error "Values file not found: $VALUES_FILE"
    exit 1
fi

# We authenticate helm to registry (implicit for public artifacts but safe to run)
# Run helm install / upgrade
helm upgrade --install spanner-omni "$CHART_URL" \
    --version "$CHART_VERSION" \
    --namespace "$NAMESPACE" \
    --create-namespace \
    -f "$VALUES_FILE"

log_success "Helm chart deployment command executed successfully."

# 3. Wait for Pods to be Ready
log_info "Waiting for Spanner Omni pods to be ready..."
# SingleServer: true will deploy statefulsets named spanner-omni or pods with labels
kubectl wait --namespace "$NAMESPACE" \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/name=spanner-omni \
    --timeout=300s

log_success "Spanner Omni pods are Ready!"

# 4. Verify deployment resources
log_info "Verifying deployed Kubernetes resources..."
echo "--------------------------------------------------"
kubectl get pods -n "$NAMESPACE"
echo "--------------------------------------------------"
kubectl get svc -n "$NAMESPACE"
echo "--------------------------------------------------"
kubectl get deployments -n "$NAMESPACE" || kubectl get statefulsets -n "$NAMESPACE"
echo "--------------------------------------------------"

# 5. Apply Prometheus / Grafana Monitoring Configs
log_info "Deploying GKE Monitoring configuration..."
MONITORING_FILE="manifests/prometheus-operator.yaml"

if [ -f "$MONITORING_FILE" ]; then
    # We apply the PodMonitoring manifest. If it fails due to missing CRD, we log warning but don't crash
    if kubectl apply -f "$MONITORING_FILE" 2>/dev/null; then
        log_success "Applied Prometheus monitoring configuration successfully."
    else
        log_warning "Could not apply GMP/ServiceMonitor CRDs. Ensure Managed Prometheus is enabled on cluster."
        log_warning "You can run: gcloud container clusters update spanner-omni-gke --enable-managed-prometheus --region=europe-west4"
    fi
fi

log_success "Spanner Omni installation and configuration completed!"
