terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0, < 4.0"
    }
  }
}

resource "helm_release" "pgweb" {
  name             = "pgweb"
  repository       = "https://charts.ectobit.com"
  chart            = "pgweb"
  version          = "0.1.9"
  namespace        = "database"
  create_namespace = true
  values           = [file("${path.module}/pgweb.yml")]
}
