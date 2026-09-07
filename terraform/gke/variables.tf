variable "project_id" {
  description = "GCP project ID to create the cluster in"
  type        = string
}

variable "region" {
  description = "GCP region for the Autopilot cluster"
  type        = string
  default     = "asia-southeast1"
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "gitops-demo"
}

variable "argocd_chart_version" {
  description = "Argo CD Helm chart version"
  type        = string
  default     = "7.8.0"
}
