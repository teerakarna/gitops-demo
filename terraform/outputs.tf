output "kubeconfig" {
  description = "kubeconfig for the kind cluster"
  value       = kind_cluster.gitops_demo.kubeconfig
  sensitive   = true
}

output "argocd_url" {
  description = "ArgoCD UI URL"
  value       = "http://localhost:30080"
}
