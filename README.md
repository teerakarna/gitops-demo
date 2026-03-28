# gitops-demo

GitOps source of truth for the [From Commit to Cluster](https://teerakarna.github.io/posts/gitops-pipeline-demo/) tutorial.

Contains the infrastructure bootstrap (Terraform: kind cluster + ArgoCD), ArgoCD Application definitions, and per-environment Helm values for `service-demo`.

## Quick start

### 1. Bootstrap the cluster and install ArgoCD

```bash
cd terraform
terraform init
terraform apply
```

This creates a kind cluster named `gitops-demo` and installs ArgoCD on NodePort 30080.

### 2. Get the ArgoCD admin password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

### 3. Log in to ArgoCD

```bash
argocd login localhost:30080 --username admin --insecure
# UI: http://localhost:30080
```

### 4. Apply stable environment Applications

```bash
kubectl apply -f argocd/apps/
```

### 5. Apply the ephemeral PR ApplicationSet

```bash
# Create the GitHub token secret first
kubectl create secret generic github-token \
  -n argocd \
  --from-literal=token=<your-github-pat>

kubectl apply -f argocd/appsets/ephemeral.yaml
```

### 6. Create an ArgoCD API token for CI

```bash
argocd account generate-token --account admin
# Add this as ARGOCD_TOKEN in your service-demo repo secrets
```

---

## Self-hosted runner setup

```bash
# Register in service-demo repo: Settings → Actions → Runners → New self-hosted runner
# After downloading and configuring:
./run.sh --labels kind
```

The runner needs `kubectl` configured for the kind cluster and the `argocd` CLI installed.

---

## Repository structure

```
terraform/                      # Kind cluster + ArgoCD bootstrap
  main.tf
  variables.tf
  outputs.tf

bootstrap/
  argocd-values.yaml            # ArgoCD Helm values (NodePort, insecure mode)

argocd/
  apps/
    dev.yaml                    # ArgoCD Application: dev namespace
    preprod.yaml                # ArgoCD Application: preprod namespace
    prod.yaml                   # ArgoCD Application: prod namespace (manual sync)
  appsets/
    ephemeral.yaml              # ApplicationSet: one app per open PR

values/
  dev/service-demo.yaml         # Updated by cd.yml on merge to main
  preprod/service-demo.yaml     # Updated by cd.yml on merge to main
  prod/service-demo.yaml        # Updated by release.yml on manual release
  pr/                           # Written by ci.yml per PR; cleaned up on PR close
```

---

## How ArgoCD multi-source works

The stable Applications use ArgoCD's [multi-source feature](https://argo-cd.readthedocs.io/en/stable/user-guide/multiple_sources/) (v2.6+):

- **Chart source**: `service-demo` repo at `main`, path `chart/service-demo`
- **Values source**: `gitops-demo` repo (this repo), values file per environment

This separates "what the chart looks like" from "how it is configured per environment". The CI pipeline only ever writes to the values files in this repo — it never touches the chart.

---

## Production notes

- `prod.yaml` has `syncPolicy.automated` disabled intentionally. ArgoCD shows the diff; the release workflow triggers the sync.
- For production use, replace the `admin` token with a dedicated ArgoCD service account and rotate it regularly.
- Namespace isolation via Kubernetes `NetworkPolicy` is not configured here. Add it before running anything sensitive.
