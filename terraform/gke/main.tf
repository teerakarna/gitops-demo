terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31"
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

  # Restrict the control plane API to known CIDR blocks. Without this it is
  # reachable from any IP on the internet. See variables.tf for how to set it.
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.authorized_cidr_blocks
      content {
        cidr_block   = cidr_blocks.value
        display_name = "authorized-${cidr_blocks.key}"
      }
    }
  }
}

# Short-lived access token for the kubernetes/helm providers, refreshed on every run
# from the credentials `gcloud auth application-default login` set up.
data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.gitops_demo.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.gitops_demo.master_auth[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${google_container_cluster.gitops_demo.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.gitops_demo.master_auth[0].cluster_ca_certificate)
  }
}

resource "kubernetes_namespace" "namespaces" {
  for_each = toset(["dev", "preprod", "prod"])

  metadata {
    name = each.key
  }

  depends_on = [google_container_cluster.gitops_demo]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = "argocd"
  create_namespace = true
  wait             = true
  timeout          = 300

  values = [file("${path.module}/../../bootstrap/argocd-values-gke.yaml")]

  depends_on = [google_container_cluster.gitops_demo]
}
