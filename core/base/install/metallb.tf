resource "kubernetes_namespace" "metallb-namespace" {
  metadata {
    name = "metallb-system"
  }
}

resource "helm_release" "metallb" {
  name = "metallb"
  repository = "https://metallb.github.io/metallb"
  chart = "metallb"
  namespace = kubernetes_namespace.metallb-namespace.id
}
