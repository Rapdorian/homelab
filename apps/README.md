# apps/

First-party applications, reconciled by Flux from `clusters/homelab/apps.yaml`.

Each app gets its own directory with a `kustomization.yaml`. Infrastructure these
apps depend on (Postgres, Valkey, observability, Authentik) is reconciled first
by the `infrastructure` Kustomization and consumed via in-cluster DNS:

- PostgreSQL: `postgres.databases.svc.cluster.local:5432`
- Valkey:     `valkey-primary.databases.svc.cluster.local:6379`
- OTLP/Tempo: `tempo.observability.svc.cluster.local:4317` (gRPC) / `:4318` (HTTP)
- Loki:       push via the Loki gateway

## Authentication

Services are protected by Authentik. Two patterns:

- **OIDC** (native support, e.g. Grafana): create an OAuth2 provider +
  application in `infrastructure/auth/blueprints-configmap.yaml`.
- **Forward auth** (no native SSO): add the shared Traefik middleware to the
  Ingress:

  ```yaml
  traefik.ingress.kubernetes.io/router.middlewares: default-authentik-forwardauth@kubernetescrd,default-security-headers@kubernetescrd
  ```

  and add a matching proxy provider + application + group binding in Authentik
  (`hello-world.yml` is a worked example).

`example-app/hello-world.yml` demonstrates the forward-auth pattern.
