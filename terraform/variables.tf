variable "cluster_name" {
  description = "Name of the kind cluster"
  type        = string
  default     = "gitops-demo"
}

variable "argocd_chart_version" {
  description = "Argo CD Helm chart version"
  type        = string
  default     = "7.8.0"
}
