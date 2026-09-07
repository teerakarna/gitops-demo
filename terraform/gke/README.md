# GKE cloud path

Terraform for the cloud version of the demo: a GKE Autopilot cluster. It runs the
same GitOps setup as the local kind path, on Google Cloud.

## Cost

This creates real cloud resources and costs money while it runs.

- GKE waives the management fee for one Autopilot or zonal cluster per billing account.
- You still pay for the pod resources the workloads use (small for this demo).
- Always tear it down when you are done (see Teardown).

## Prerequisites

- A GCP project with billing enabled.
- `gcloud` authenticated: `gcloud auth application-default login`.
- The Kubernetes Engine API enabled: `gcloud services enable container.googleapis.com`.

## Use

```
terraform init
terraform apply -var project_id=YOUR_PROJECT
gcloud container clusters get-credentials gitops-demo --region asia-southeast1 --project YOUR_PROJECT
```

ArgoCD install and the app wiring come in the next step.

## Teardown

```
terraform destroy -var project_id=YOUR_PROJECT
```
