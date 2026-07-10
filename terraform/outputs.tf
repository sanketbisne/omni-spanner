output "cluster_name" {
  value       = google_container_cluster.primary.name
  description = "The name of the GKE cluster."
}

output "cluster_endpoint" {
  value       = google_container_cluster.primary.endpoint
  description = "The endpoint for the GKE cluster."
}

output "region" {
  value       = google_container_cluster.primary.location
  description = "The region of the GKE cluster."
}

output "kubectl_connection_command" {
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${google_container_cluster.primary.location} --project ${var.project_id}"
  description = "Use this command to configure kubectl access to the newly deployed cluster."
}
