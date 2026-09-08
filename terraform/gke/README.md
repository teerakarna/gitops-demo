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

The GKE control plane API only accepts connections from CIDR blocks you list
explicitly, so find your public IP first:

```
curl -s ifconfig.me
```

```
terraform init
terraform apply -var project_id=YOUR_PROJECT -var 'authorized_cidr_blocks=["YOUR_IP/32"]'
gcloud container clusters get-credentials gitops-demo --region asia-southeast1 --project YOUR_PROJECT
```

This also installs ArgoCD, with a LoadBalancer service so it gets a real external IP
(see `../../bootstrap/argocd-values-gke.yaml`). Find the IP with:

```
kubectl get svc argocd-server -n argocd
```

It stays insecure (no TLS), the same as the local kind path. Do not expose this
beyond the demo.

## Wire up the Applications

The dev/preprod/prod Applications and the ephemeral-PR ApplicationSet in
`../../argocd/` are the same files used on the local kind path. They target
`https://kubernetes.default.svc` (the API server ArgoCD itself runs on), so
nothing about them is kind- or GKE-specific.

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

argocd login <EXTERNAL-IP> --username admin --insecure
# UI: https://<EXTERNAL-IP>

kubectl apply -f ../../argocd/apps/

kubectl create secret generic github-token \
  -n argocd \
  --from-literal=token=<your-github-pat>
kubectl apply -f ../../argocd/appsets/ephemeral.yaml
```

The only difference from the local path (see the top-level README) is logging in
with the LoadBalancer's external IP instead of `localhost:30080`.

## Teardown

```
terraform destroy -var project_id=YOUR_PROJECT
```
