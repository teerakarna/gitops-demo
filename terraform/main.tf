terraform {
  required_version = ">= 1.9"

  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.4"
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

resource "kind_cluster" "gitops_demo" {
  name           = var.cluster_name
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
      # Expose port 80 on localhost for easy access to NodePort services
      extra_port_mappings {
        container_port = 30080
        host_port      = 30080
      }
    }
  }
}

provider "kubernetes" {
  host                   = kind_cluster.gitops_demo.endpoint
  client_certificate     = kind_cluster.gitops_demo.client_certificate
  client_key             = kind_cluster.gitops_demo.client_key
  cluster_ca_certificate = kind_cluster.gitops_demo.cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = kind_cluster.gitops_demo.endpoint
    client_certificate     = kind_cluster.gitops_demo.client_certificate
    client_key             = kind_cluster.gitops_demo.client_key
    cluster_ca_certificate = kind_cluster.gitops_demo.cluster_ca_certificate
  }
}

resource "kubernetes_namespace" "namespaces" {
  for_each = toset(["dev", "preprod", "prod"])

  metadata {
    name = each.key
  }

  depends_on = [kind_cluster.gitops_demo]
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

  values = [file("${path.module}/../bootstrap/argocd-values.yaml")]

  depends_on = [kind_cluster.gitops_demo]
}
