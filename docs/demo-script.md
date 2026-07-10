# Google I/O Connect Demo Script: Spanner Omni on GKE

**Session Title:** Running Spanner Anywhere: End-to-End Spanner Omni Deployment  
**Role:** Senior GCP Engineer / Developer Advocate  
**Target Audience:** Platform Engineers, Cloud Architects, Database Administrators  

---

## Demo Overview & Timeline

| Time | Session Phase | Action | Key Talking Points |
| :--- | :--- | :--- | :--- |
| **0:00 - 0:03** | Introduction | Speaker Intro & Architecture Overview | Spanner anywhere, local developer setups, hybrid cloud, TrueTime emulator. |
| **0:03 - 0:08** | Setup & Cluster | Run Scripts 01 to 04 | GKE Standard Cluster, VPC Native, Terraform vs. CLI. |
| **0:08 - 0:11** | Deploying Spanner | Run Scripts 05 and 06 | Helm charts, OCI registries, StatefulSets in Kubernetes. |
| **0:11 - 0:13** | Port-Forward & UI | Run Script 07 | Accessing ports 15000 and 15026, web-based UI console. |
| **0:13 - 0:17** | Data & SQL Demo | Run Scripts 08 and 09 | Spanner CLI, seeding retail sample, executing complex joins. |
| **0:17 - 0:20** | Monitoring & Close | Inspect metrics & cleanup | Prometheus metrics export, system insights, cleanup. |

---

## Step-by-Step Scripted Flow

### Phase 1: Intro & Architecture (0:00 - 0:03)
* **Speaker Script:**
  > "Hello everyone! Welcome to this session on Google Cloud Spanner Omni. Today, we're demonstrating how you can take the core capabilities of Google's flagship globally distributed database—Spanner—and run it anywhere: in your own Kubernetes clusters, edge nodes, or even local developer machines. We're going to provision a GKE Standard cluster, deploy Spanner Omni using the official Helm chart, seed a retail database, and execute analytics queries."

* **Slide/Visual:** Present the architecture diagram showing GKE, Spanner Omni namespace, and port forwarding.

---

### Phase 2: System Setup (0:03 - 0:08)
* **Speaker Script:**
  > "First, let's verify our environment. We have standard scripts that validate prerequisites, create the GCP project, and activate required APIs."

* **Live Action:** Execute scripts in the terminal:
  ```bash
  # Check local environment diagnostics
  ./scripts/01-prerequisites.sh
  
  # Initialize the project and billing
  export GCP_PROJECT_ID="io-connect-spanner-omni-demo"
  ./scripts/02-create-project.sh
  ./scripts/03-enable-apis.sh
  
  # Deploy the GKE Cluster
  ./scripts/04-create-gke.sh
  ```

---

### Phase 3: Helm Deployment (0:08 - 0:11)
* **Speaker Script:**
  > "With our GKE cluster ready and kubectl authenticated, we'll download the Spanner Omni CLI and deploy the container using Helm. We use the official OCI registry chart hosted by Google."

* **Live Action:**
  ```bash
  # Download Spanner CLI
  ./scripts/05-install-tools.sh
  
  # Deploy Helm release
  ./scripts/06-install-spanner-omni.sh
  ```
* **Speaker Script:**
  > "Notice how Helm creates a StatefulSet in our `spanner-omni` namespace. The script polls and waits until the pods become fully Ready, ensuring TrueTime synchronizers are initialized."

---

### Phase 4: Port Forwarding & Web UI (0:11 - 0:13)
* **Speaker Script:**
  > "Now we'll forward ports to connect our local machine to the GKE deployment. We expose port 15000 for database clients and port 15026 for the Web Console."

* **Live Action:**
  ```bash
  ./scripts/07-port-forward.sh
  ```
* **Speaker Script:**
  > "Let's open our browser and navigate to `http://localhost:15026`. We can see the active Spanner Omni Web Console, which provides instant feedback on deployment health."

---

### Phase 5: Database Seeding & SQL Demo (0:13 - 0:17)
* **Speaker Script:**
  > "Now, let's load sample data. Spanner Omni comes with a built-in seeder for a Retail shop. Let's create the database and seed it."

* **Live Action:**
  ```bash
  # Seed retail database
  ./scripts/08-create-sample-db.sh
  
  # Run the demo queries
  ./scripts/09-run-demo.sh
  ```

* **Talking Point:** Point out the SQL analytics output:
  > "Here, we're running a multi-table JOIN query that groups orders and calculates revenue by product category. Notice the sub-millisecond response time on our GKE cluster. We also demonstrate a vector cosine distance query, which is crucial for modern AI-driven product recommendations directly inside the database."

---

### Phase 6: Monitoring & Cleanup (0:17 - 0:20)
* **Speaker Script:**
  > "Finally, Spanner Omni exports standard metrics on port 15012. These are scraped by GKE's Managed Prometheus and visualized in our custom Grafana dashboard. This completes our demo! Let's clean up our cloud resources."

* **Live Action:**
  ```bash
  ./scripts/cleanup.sh
  ```
