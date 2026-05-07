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

  values = [ file("${path.module}/github-runners.yml") ]

  depends_on = [helm_release.arc]
}

resource "kubernetes_role" "terraform-state-reader" {
  metadata {
    name      = "terraform-state-reader"
    namespace = "terraform-states"
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

resource "kubernetes_role_binding" "terraform-state-reader-binding" {
  metadata {
    name      = "terraform-state-reader-binding"
    namespace = "terraform-states"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.terraform-state-reader.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "homelab-gha-rs-no-permission"
    namespace = "arc-systems"
  }

  depends_on = [helm_release.homelab]
}
