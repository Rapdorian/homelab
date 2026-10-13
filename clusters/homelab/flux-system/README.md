# flux-system

This directory is managed by `flux bootstrap` / `flux install` and is
**generated**. It contains the Flux controllers, the `GitRepository` source,
and the self-referential `flux-system` Kustomization.

Do not hand-edit. To (re)bootstrap this cluster from the repository:

```sh
flux bootstrap github \
  --owner=Rapdorian \
  --repository=homelab \
  --branch=flux \
  --path=clusters/homelab \
  --personal
```

`--path=clusters/homelab` is important: it decides which directory Flux watches
for `infrastructure.yaml`, `apps.yaml`, and `flux-system/`.
