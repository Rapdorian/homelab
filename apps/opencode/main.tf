terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0, < 4.0"
    }
  }
}

resource "helm_release" "opencode" {
  name           = "prometheus"
  chart          = "oci://ghcr.io/kubeopencode/helm-charts/kubeopencode"
  namespace      = "adlc"
  create_namespace = true
}
