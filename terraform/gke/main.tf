terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# GKE Autopilot cluster for the cloud path of the demo. Autopilot means Google runs
# the nodes and you pay for the pod resources your workloads use. The management fee
# is waived for one Autopilot or zonal cluster per billing account. Tear down when done.
resource "google_container_cluster" "gitops_demo" {
  name     = var.cluster_name
  location = var.region

  enable_autopilot = true

  # Demo only: let "terraform destroy" remove the cluster without a manual step.
  deletion_protection = false
}
