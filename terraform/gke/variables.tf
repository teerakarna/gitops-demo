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

variable "authorized_cidr_blocks" {
  description = <<-EOT
    CIDR blocks allowed to reach the GKE control plane API, e.g. your own IP as
    a /32. No default: you must set this, so the control plane is never open to
    the whole internet by accident.

    Find your public IP with: curl -s ifconfig.me
  EOT
  type        = list(string)
}
