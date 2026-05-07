# AGENTS.md - Homelab Terraform

## What this is
Terraform IaC for a k3s homelab cluster. State is stored as Kubernetes secrets in namespace `terraform-states`. All providers must run **in-cluster** (`in_cluster_config = true`).

## Developer commands
- `make base` — initializes and applies `core/base/install` then `core/base/config` (MetalLB, Traefik)
- `make ci-runner` — initializes and applies `ci-runner/` (GitHub Actions runners)
- `cd <module> && terraform init && terraform apply --auto-approve --lock-timeout=300s` — manual apply for any submodule

## Deployment order / dependencies
```
core/base  (MetalLB, Traefik config)  ← run first
dns
dbs        (PostgreSQL)
auth       (Authentik)               ← depends_on dbs
apps       (Grafana, Prometheus)     ← depends_on dbs
ci-runner  (GitHub ARC)              ← standalone
```

## Terraform state
- Backend: `kubernetes` in namespace `terraform-states`
- Each submodule has its own `secret_suffix` (e.g. `core-base-install`, `core-base-config`)
- `.terraform/` and `.terraform.lock.hcl` are gitignored — always run `terraform init` before apply

## Key gotchas
- **`--lock-timeout=300s`** is required in makefile; omitting it causes lock contention errors
- Root `main.tf` passes `module.auth.authentik_token` and `module.dbs.postgres_password` to providers — these are only available after their modules are applied
- `providers.tf` at root defines `postgresql` provider pointing to `postgresql.database.svc.cluster.local` and `authentik` provider at `http://authentik-server.authentik.svc.cluster.local`
- `core/identity` and `core/storage` directories exist but are **not referenced** by any root module (possibly unused or WIP)
- `.github/workflows/storage.yml` and `identity.yml` are empty stubs

## CI/CD
- Workflows run on self-hosted runner: `runs-on: homelab`
- `base-cluster.yml` triggers on `core/base/**` changes → runs `make base`
- `ci-runner.yml` triggers on `ci-runner/**` changes → runs `make ci-runner`
- GitHub token is required as input variable for `ci-runner` and root `dev-tools` module

## Network
- MetalLB IP pool: `10.0.1.50-10.0.1.255` and `10.0.0.55/32`
- Traefik load balancer IP: `10.0.0.55`
- External domain: `svc.jpruitt.dev`
