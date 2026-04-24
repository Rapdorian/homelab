variable "github_token" {
  type      = string
  sensitive = true
}

resource "helm_release" "arc" {
  name             = "arc-controller"
  chart            = "oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller"
  namespace        = "arc-systems"
  create_namespace = true
}

resource "helm_release" "homelab" {
  name             = "homelab-runners"
  chart            = "oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set"
  namespace        = "arc-systems"
  create_namespace = true

  values = [
    yamlencode({
      githubConfigUrl = "https://github.com/Rapdorian/homelab"
      githubConfigSecret = {
        github_token = var.github_token
      }
    })
  ]

  depends_on = [helm_release.arc]
}
