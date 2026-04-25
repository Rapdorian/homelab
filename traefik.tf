resource "kubernetes_manifest" "traefik_config" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChartConfig"
    metadata = {
      name      = "traefik"
      namespace = "kube-system"
    }
    spec = {
      valuesContent = <<-EOT
        service:
          annotations:
            metallb.universe.tf/loadBalancerIPs: 10.0.0.55
      EOT
    }
  }
}
