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

output "argocd_service_note" {
  description = "How to find the ArgoCD external IP once it is assigned"
  value       = "kubectl get svc argocd-server -n argocd  (EXTERNAL-IP can take a minute to appear)"
}
