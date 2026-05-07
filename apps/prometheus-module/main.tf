terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0, < 4.0"
    }
  }
}

resource "helm_release" "prometheus" {
  name           = "prometheus"
  chart          = "oci://ghcr.io/prometheus-community/charts/prometheus"
  namespace      = "metric"
  create_namespace = true
  values         = [file("${path.module}/prometheus.yml")]
}
