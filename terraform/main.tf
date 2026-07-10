terraform {
  required_version = ">= 1.3.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# --------------------------------------------------------------------------------
# 1. VPC Network and Subnetwork (Best practice for VPC-native GKE clusters)
# --------------------------------------------------------------------------------
resource "google_compute_network" "vpc" {
  name                    = "${var.cluster_name}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.cluster_name}-subnet"
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = "10.0.0.0/16"

  # IP ranges for GKE Pods and Services (VPC-native configuration)
  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = "172.16.0.0/16"
  }
  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = "172.20.0.0/20"
  }
}

# --------------------------------------------------------------------------------
# 3. GKE Standard Cluster Configuration
# --------------------------------------------------------------------------------
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region

  # We create a regional cluster, but define a single node pool separately.
  # This is the recommended Terraform pattern for GKE.
  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.subnet.id

  # Enable VPC-native traffic routing
  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods"
    services_secondary_range_name = "gke-services"
  }

  # We must delete the default node pool and replace it with our own configured pool
  remove_default_node_pool = true
  initial_node_count       = 1

  # Add GKE cluster master authorized networks or other configs if needed
  # Keep it simple for demo purposes
  deletion_protection = false

  depends_on = [google_compute_subnetwork.subnet]
}

# --------------------------------------------------------------------------------
# 4. Custom Node Pool (3 x e2-standard-4 Nodes)
# --------------------------------------------------------------------------------
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  # Enable Autoscaling
  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }

  node_config {
    preemptible  = false
    machine_type = var.machine_type

    # Standard Disk size & type for Spanner Omni workloads
    disk_size_gb = 100
    disk_type    = "pd-ssd"

    # Minimal required OAuth scopes for GKE standard node pools
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring"
    ]

    # Labels for node-selectors if needed
    labels = {
      env = "demo"
      app = "spanner-omni"
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}
