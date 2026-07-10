variable "project_id" {
  type        = string
  description = "The Google Cloud Project ID to deploy resources to."
}

variable "region" {
  type        = string
  default     = "europe-west4"
  description = "The region to deploy the GKE cluster and associated resources."
}

variable "zone" {
  type        = string
  default     = "europe-west4-a"
  description = "The zone to deploy the primary GKE node pool."
}

variable "cluster_name" {
  type        = string
  default     = "spanner-omni-gke"
  description = "The name of the GKE cluster."
}

variable "machine_type" {
  type        = string
  default     = "e2-standard-4"
  description = "The machine type for GKE node pool members. E2-standard-4 is recommended for Spanner Omni."
}

variable "node_count" {
  type        = number
  default     = 3
  description = "The initial node count for the GKE cluster."
}
