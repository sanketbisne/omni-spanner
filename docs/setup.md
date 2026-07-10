# Spanner Omni GKE Setup & Installation Guide

This guide describes how to deploy Google Cloud Spanner Omni on a Google Kubernetes Engine (GKE) Standard cluster. 

---

## Architecture Overview

The deployment consists of:
1. **GKE Standard Cluster:** A regional cluster in `us-central1` running across three availability zones with three `e2-standard-4` worker nodes.
2. **Spanner Omni Namespace (`spanner-omni`):** Hosts the Spanner Omni container instance deployed via Helm, exposing database operations on port `15000` and the Console UI on port `15026`.
3. **Monitoring Namespace (`spanner-omni`):** Exposes Prometheus metrics via port `15012`, scraped by GKE-native Managed Service for Prometheus (GMP).

---

## Prerequisites

Before deploying, ensure you have:
- A Google Cloud Account with an active billing profile.
- Owner or Editor roles on the target project (to create resources and link billing).
- The following local command-line tools:
  - `gcloud` (authenticated to your Google Account)
  - `kubectl`
  - `helm` (v3+)
  - `docker` (optional, for local container checks)
  - `jq` and `yq`

---

## Step-by-Step Deployment

Follow these sequential steps to run the automation scripts.

### Step 1: Run Diagnostics Check
Run the prerequisites scanner to ensure all required CLI binaries and authentication states are valid.
```bash
./scripts/01-prerequisites.sh
```

### Step 2: Establish the GCP Project
Configure or create the target Google Cloud Project. To automatically link a billing account (required for GKE), set the billing account ID as an environment variable:
```bash
export GCP_PROJECT_ID="your-project-id-here"
export GCP_BILLING_ACCOUNT_ID="012345-6789AB-CDEF01" # Optional, links billing if creating new project

./scripts/02-create-project.sh
```

### Step 3: Enable Google Cloud APIs
Activate all services required by GKE, compute instances, artifact registries, and IAM policies:
```bash
./scripts/03-enable-apis.sh
```

### Step 4: Provision the GKE Cluster
You can provision the cluster in two ways:

#### Option A: Direct gcloud Deployment (Default)
Deploys a regional GKE Standard cluster with autoscaling enabled:
```bash
./scripts/04-create-gke.sh
```

#### Option B: Declarative Terraform Deployment
Ensure you have `terraform` installed, then run:
```bash
export USE_TERRAFORM="true"
./scripts/04-create-gke.sh
```

### Step 5: Install Local Spanner Omni CLI
Download and extract the architecture-specific Spanner Omni CLI tool locally under `./bin/spanner`:
```bash
./scripts/05-install-tools.sh
```

### Step 6: Deploy Spanner Omni to GKE
Deploys the Spanner Omni container via Helm, waits for the pods to transition to the `Ready` status, and deploys monitoring resources:
```bash
./scripts/06-install-spanner-omni.sh
```

### Step 7: Establish Port Forwarding
Start background port-forwarding to make the GKE-hosted Spanner instance accessible locally:
```bash
./scripts/07-port-forward.sh
```

### Step 8: Seed the Sample Retail Database
Seed the e-commerce retail sample database (`retail`) inside the Spanner container:
```bash
./scripts/08-create-sample-db.sh
```

### Step 9: Execute the Demo SQL Script
Run the analytical sales and customer queries, displaying the formatted tables:
```bash
./scripts/09-run-demo.sh
```

---

## Cleanup

When you are done with the session, run the cleanup script to terminate port forwards, delete the GKE cluster, and clean up temporary local binaries:
```bash
./scripts/cleanup.sh
```
