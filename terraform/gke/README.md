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

This also installs ArgoCD, with a LoadBalancer service so it gets a real external IP
(see `../../bootstrap/argocd-values-gke.yaml`). Find the IP with:

```
kubectl get svc argocd-server -n argocd
```

It stays insecure (no TLS), the same as the local kind path. Do not expose this
beyond the demo.

The app wiring (dev/preprod/prod Applications, the ephemeral-PR ApplicationSet)
comes in the next step.

## Teardown

```
terraform destroy -var project_id=YOUR_PROJECT
```
