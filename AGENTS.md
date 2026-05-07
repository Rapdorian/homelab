# AGENTS.md - Homelab Terraform

## What this is
Terraform IaC for a k3s homelab cluster. State is stored as Kubernetes secrets in namespace `terraform-states`. All providers run **in-cluster** (empty `kubernetes {}` block).

## Developer commands
- `make core` — applies all core layers in order: base → storage → identity
- `make base` — initializes and applies `core/base/install` then `core/base/config` (MetalLB, Traefik)
- `make core-storage` — initializes and applies `core/storage` (PostgreSQL)
- `make core-identity` — initializes and applies `core/identity` (Authentik)
- `make ci-runner-secret GITHUB_TOKEN=<token>` — creates k8s secret for GitHub Actions runner token
- `make ci-runner` — initializes and applies `ci-runner/` (GitHub Actions runners)
- Local `terraform init` needs `KUBE_CONFIG_PATH=~/.kube/config` — providers auto-detect in-cluster, but the backend reads kubeconfig

## Deployment order / dependencies
```
core/base/install → core/base/config → core/storage → core/identity
ci-runner (standalone, depends on core/base for MetalLB)
```

## Terraform state
- Backend: `kubernetes` in namespace `terraform-states`
- Locks stored as **Leases** (`coordination.k8s.io/v1`) in namespace `terraform-states`, named `lock-tfstate-default-<suffix>`
- Each module has its own `secret_suffix` (e.g. `core-base-install`, `core-storage`, `core-identity`, `ci-runner`)
- `.terraform/` and `.terraform.lock.hcl` are gitignored — always run `terraform init` before apply

## Stuck lock recovery
If `terraform init` reports a stale lock:
```
KUBE_CONFIG_PATH=~/.kube/config kubectl delete lease lock-tfstate-default-<suffix> -n terraform-states
rm -rf .terraform && KUBE_CONFIG_PATH=~/.kube/config terraform init
```

## CI/CD
- Workflows run on self-hosted runner: `runs-on: homelab`
- `base-cluster.yml` triggers on `core/**` changes → runs terraform directly
- `ci-runner.yml` triggers on `ci-runner/**` changes → runs terraform directly
- GitHub token is stored as k8s secret `github-token` in namespace `arc-systems`

## Network
- MetalLB IP pool: `10.0.1.50-10.0.1.255` and `10.0.0.55/32`
- Traefik load balancer IP: `10.0.0.55`
- External domain: `svc.jpruitt.dev`

## Module boundaries
- `core/base/install` — MetalLB namespace + helm chart
- `core/base/config` — MetalLB IP pool + L2Advertisement + Traefik HelmChartConfig + split-horizon CoreDNS
- `core/storage` — PostgreSQL helm chart, writes `postgres-cred` secret to `terraform-states`
- `core/identity` — Reads `postgres-cred`, creates authentik db/user, deploys authentik helm chart
- `ci-runner` — GitHub ARC controller + runner scale set, RBAC for terraform state access
- `core/identity` and `core/storage` are NOT referenced by root `main.tf` — they are standalone layered modules
