# gitops-demo

GitOps source of truth for the [From Commit to Cluster](https://teerakarna.github.io/posts/gitops-pipeline-demo/) tutorial.

This repo is the half of the system that ArgoCD watches. It contains the infrastructure bootstrap (Terraform: kind cluster + ArgoCD), ArgoCD Application and ApplicationSet definitions, and per-environment Helm values for [`service-demo`](https://github.com/teerakarna/service-demo). The CI/CD pipelines in `service-demo` commit to this repo; ArgoCD reads from it and reconciles the cluster. Neither pipeline touches the cluster directly.

---

## Repository structure

```
terraform/
  main.tf                       # kind cluster + namespace + ArgoCD Helm release
  variables.tf
  outputs.tf

bootstrap/
  argocd-values.yaml            # ArgoCD Helm values (NodePort 30080, insecure mode)

argocd/
  apps/
    dev.yaml                    # Application: dev namespace (manual sync — tracks releases)
    preprod.yaml                # Application: preprod namespace (auto-sync)
    prod.yaml                   # Application: prod namespace (manual sync)
  appsets/
    ephemeral.yaml              # ApplicationSet: one app per open PR (pullRequest generator)

values/
  dev/service-demo.yaml         # Updated by release.yml alongside prod (same v{X.Y.Z} tag)
  preprod/service-demo.yaml     # Updated by cd.yml on every merge to main (main-{sha} tag)
  prod/service-demo.yaml        # Updated by release.yml on manual release (v{X.Y.Z} tag)
  pr/                           # Written by ci.yml per PR; cleaned up on PR close
```

---

## Quick start

### 1. Bootstrap the cluster and install ArgoCD

```bash
cd terraform
terraform init
terraform apply
```

Creates a kind cluster named `gitops-demo`, three namespaces (`dev`, `preprod`, `prod`), and installs ArgoCD via Helm on NodePort 30080.

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

### 4. Apply the stable environment Applications

```bash
kubectl apply -f argocd/apps/
```

This creates three ArgoCD Applications — `service-demo-dev`, `service-demo-preprod`, and `service-demo-prod`. They will show as `OutOfSync` until a values file contains a real image tag.

### 5. Apply the ephemeral PR ApplicationSet

```bash
# Create the GitHub token secret first — fine-grained PAT with read access to service-demo
kubectl create secret generic github-token \
  -n argocd \
  --from-literal=token=<your-github-pat>

kubectl apply -f argocd/appsets/ephemeral.yaml
```

The ApplicationSet polls the `service-demo` repo for open PRs and automatically creates and prunes an ArgoCD Application per PR.

### 6. Create an ArgoCD API token for CI

```bash
argocd account generate-token --account admin
# Add as ARGOCD_TOKEN in your service-demo repo secrets
```

CI uses this token for `argocd app wait` in the preprod test job.

### Cloud path (optional)

The steps above use a local kind cluster. To run the same setup on a real GKE
cluster instead, see [`terraform/gke/README.md`](terraform/gke/README.md). It
costs money while running: read the cost note there first.

---

## Self-hosted runner

The `deploy-ephemeral`, `smoke-test`, and `preprod-tests` jobs in `service-demo` run on a self-hosted runner with access to the kind cluster. Register one with the `kind` label:

```bash
# In service-demo: Settings → Actions → Runners → New self-hosted runner
# After downloading and configuring the runner:
./run.sh --labels kind
```

The runner needs `kubectl` pointing at the kind cluster and the `argocd` CLI installed.

---

## How it works

### ArgoCD multi-source

All three stable Applications use ArgoCD's [multi-source feature](https://argo-cd.readthedocs.io/en/stable/user-guide/multiple_sources/) (v2.6+):

- **Chart source**: `service-demo` repo at `main`, path `chart/service-demo`
- **Values source**: this repo, `values/{env}/service-demo.yaml`

This separates chart definition from environment configuration. The CI/CD pipelines only ever write to values files in this repo — they never modify the chart. The ephemeral ApplicationSet uses a single source (the chart at the PR's HEAD SHA) with Helm parameters instead.

### Sync policies

| Environment | Sync policy | Reason |
|---|---|---|
| `preprod` | Auto-sync (prune + self-heal) | Needs to stay current with every merge to main |
| `dev` | Manual | Tracks releases, not snapshots; promoted atomically with prod |
| `prod` | Manual | A human (or the release workflow) triggers the sync; auto-sync in prod means any commit immediately affects live traffic |
| `pr-{N}` | Auto-sync (prune + self-heal) | Ephemeral — created and destroyed per PR lifecycle |

### Values ownership

| File | Written by | Image tag format |
|---|---|---|
| `values/preprod/service-demo.yaml` | `cd.yml` on merge to main | `main-{sha}` |
| `values/dev/service-demo.yaml` | `release.yml` on manual release | `v{X.Y.Z}` |
| `values/prod/service-demo.yaml` | `release.yml` on manual release | `v{X.Y.Z}` |
| `values/pr/{N}.yaml` | `ci.yml` on PR open/update | `pr-{N}-{sha}` |

`dev` and `prod` are always updated in a single atomic commit by the release workflow — they are guaranteed to be on the same tag.

### Production-parity dev and service discovery

`dev` always runs the latest release (`v{X.Y.Z}`), the same image as production. Ephemeral PR environments set `servicesNamespace=dev` via the ApplicationSet, which is exposed to the container as `SERVICES_NAMESPACE`. Any service-to-service call resolves via:

```
http://{service}.dev.svc.cluster.local
```

This means PR environments call production-equivalent dependencies rather than stubs or uncontrolled snapshots.

### Cluster topology

For this tutorial, all four environments run as namespaces on a single kind cluster. The intended production topology is:

- **dev cluster** — `dev` namespace + all `pr-{N}` ephemeral namespaces, colocated intentionally (in-cluster DNS for service discovery)
- **preprod cluster** — isolated so load and performance tests cannot affect other environments
- **prod cluster** — separate account, strict IAM, no CI path directly into the cluster

---

## Production notes

- Replace the `admin` token with a dedicated ArgoCD service account scoped to the minimum required permissions.
- `NetworkPolicy` is not configured. Add default-deny policies and explicit allow rules before running anything sensitive.
- The GitHub token secret (`github-token`) grants read access to the `service-demo` repo for the ApplicationSet controller. Use a fine-grained PAT scoped to that repo only.
- For production ArgoCD, consider the [app-of-apps pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/) so ArgoCD manages its own Applications rather than requiring manual `kubectl apply`.
