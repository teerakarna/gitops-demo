output "cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.gitops_demo.name
}

output "location" {
  description = "GKE cluster location"
  value       = google_container_cluster.gitops_demo.location
}

output "get_credentials" {
  description = "Command to fetch kubeconfig for the cluster"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.gitops_demo.name} --region ${google_container_cluster.gitops_demo.location} --project ${var.project_id}"
}
