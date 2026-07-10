# Troubleshooting Guide: Spanner Omni on GKE

Use this guide to diagnose and resolve issues encountered during the setup or execution of the Spanner Omni demo.

---

## 1. GKE / Resource Provisioning Issues

### Error: Quota Exceeded (e.g., CPU, IP Addresses)
* **Symptoms:** `04-create-gke.sh` fails during creation, or cluster stays in `PROVISIONING` indefinitely.
* **Cause:** Your GCP project or region has insufficient CPU quota for 3 x `e2-standard-4` machines (total 12 vCPUs).
* **Mitigation:**
  - Request a quota increase for "Compute Engine API - CPUs" in us-central1.
  - Alternatively, change the machine type to a smaller instance (e.g., `e2-standard-2`) in `scripts/04-create-gke.sh` and run it again. (Note: Spanner Omni requires at least 2 CPUs for stable performance).

### Error: Billing Not Enabled
* **Symptoms:** API enabling script `03-enable-apis.sh` or GKE provisioning fails.
* **Cause:** GKE requires an active billing account linked to the GCP project.
* **Mitigation:** Link your billing account explicitly via:
  ```bash
  gcloud beta billing projects link YOUR_PROJECT_ID --billing-account=YOUR_BILLING_ACCOUNT_ID
  ```

---

## 2. Helm / Kubernetes Deployment Issues

### Error: ImagePullBackOff / Erroneous Pulls
* **Symptoms:** Pods remain in `ImagePullBackOff` or `ErrImagePull` state.
* **Cause:** The cluster cannot pull images from `us-docker.pkg.dev/spanner-omni/images/spanner-omni`.
* **Mitigation:**
  - Verify GKE has access to the internet.
  - Verify the GKE nodes have standard Workload Identity enabled, or run:
    ```bash
    gcloud auth configure-docker us-docker.pkg.dev
    ```

### Diagnostic Commands for Pod Crashes
If a pod is in a crash loop, check the logs or description:
```bash
# Get pod status details
kubectl describe pod -n spanner-omni -l app.kubernetes.io/name=spanner-omni

# View container logs
kubectl logs -n spanner-omni -l app.kubernetes.io/name=spanner-omni --tail=100
```

---

## 3. Port Forwarding Address Collisions

### Error: "Address already in use"
* **Symptoms:** `07-port-forward.sh` logs `Address already in use` or fails to bind ports `15000` or `15026`.
* **Cause:** Another local service (e.g., another database instance or web service) is listening on these ports.
* **Mitigation:**
  - Run the following commands to find and terminate conflicting processes:
    ```bash
    # For macOS
    lsof -i :15000
    lsof -i :15026
    
    # Kill the conflicting process ID
    kill -9 <PID>
    ```
  - Alternatively, restart the port-forwarding helper script:
    ```bash
    ./scripts/07-port-forward.sh
    ```

---

## 4. Spanner Database Seeding & SQL Errors

### Error: Database Already Exists
* **Symptoms:** `08-create-sample-db.sh` prints warning and skips database seeding.
* **Cause:** The database was already seeded.
* **Mitigation:** If you want a fresh start, drop the database first:
  ```bash
  kubectl exec -it -n spanner-omni pod/YOUR_POD_NAME -- /google/spanner/bin/spanner databases delete retail
  ```

### CLI connection failures
* **Symptoms:** Local Spanner CLI prints connection errors when running queries.
* **Cause:** The local CLI is trying to connect to `localhost:15000` but port-forwarding is broken or closed.
* **Mitigation:** Restart port-forwarding: `./scripts/07-port-forward.sh`.
