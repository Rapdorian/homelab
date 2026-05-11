terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0, < 4.0"
    }
    authentik = {
      source  = "goauthentik/authentik"
      version = "~> 2025.12.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

resource "helm_release" "opencode" {
  name             = "opencode"
  chart            = "oci://ghcr.io/kubeopencode/helm-charts/kubeopencode"
  namespace        = "adlc"
  create_namespace = true
  values           = [file("${path.module}/opencode.yml")]

  depends_on = [kubernetes_manifest.traefik_forwardauth]
}