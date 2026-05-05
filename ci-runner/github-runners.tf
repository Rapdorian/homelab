variable "github_token" {
  type      = string
  sensitive = true
}

resource "helm_release" "arc" {
  name             = "arc-controller"
  chart            = "oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller"
  namespace        = "arc-systems"
  create_namespace = true

  values = [ file("${path.module}/github-controller.yml") ]
}

resource "helm_release" "homelab" {
  name             = "homelab"
  chart            = "oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set"
  namespace        = "arc-systems"
  create_namespace = true

  values = [ templatefile("${path.module}/github-runners.yml", {
    token = var.github_token
  }) ]

  depends_on = [helm_release.arc]
}
