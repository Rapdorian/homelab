# homelab2 task runner.
# Run `just` with no arguments to list targets.
#
# The cluster is reconciled by Flux (GitOps). Day-to-day you edit the repo,
# push, and let Flux apply it — or use `just reconcile` to pull immediately.

flux_path := "clusters/homelab"

# List available recipes.
default:
    @just --list

# Install Flux and connect it to this repo (one-time). Args: owner repo [branch]
bootstrap owner repo branch="flux":
    flux bootstrap github \
        --owner={{owner}} \
        --repository={{repo}} \
        --branch={{branch}} \
        --path={{flux_path}} \
        --personal

# Store the SOPS age key in the cluster (one-time, before Flux can decrypt).
age-secret:
    kubectl create secret generic sops-age -n flux-system \
        --from-file=age.agekey={{env_var('HOME')}}/.config/sops/age/keys.txt \
        --dry-run=client -o yaml | kubectl apply -f -

# Pull the repository and re-reconcile every Kustomization now.
reconcile:
    flux reconcile source git flux-system
    for k in secrets infrastructure apps; do flux reconcile kustomization "$k"; done

# Show reconciliation status.
status:
    flux get sources all -A
    flux get kustomizations -A
    flux get helmreleases -A

# Watch Kustomizations until they settle.
watch:
    flux get kustomizations --watch

# Reconcile and follow the logs of the controllers.
logs:
    flux logs --all-namespaces --follow

# Encrypt a new secret in place (must live under secrets/ and end in .enc.yaml).
encrypt file:
    sops -e -i {{file}}

# Edit an encrypted secret.
edit file:
    sops {{file}}

# Decrypt to stdout (for inspection; never write to a tracked file).
decrypt file:
    sops -d {{file}}

# Render a Kustomization locally without applying (sanity check).
build path="infrastructure":
    kustomize build {{path}}

# Show certificate / ACME order status.
certs:
    kubectl get clusterissuers
    kubectl get certificates,certificaterequests,orders -A

# Dump a kubeconfig from the local k3s server.
kubeconfig:
    k3s kubectl config view --raw
