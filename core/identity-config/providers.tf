terraform {
  backend "kubernetes" {
    secret_suffix = "core-identity-config"
    namespace     = "terraform-states"
  }

  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = ">= 2024.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# Read the bootstrap token written by core/identity
data "kubernetes_secret" "authentik-cred" {
  metadata {
    name      = "authentik-cred"
    namespace = "terraform-states"
  }
}

provider "authentik" {
  url      = "http://authentik-server.authentik.svc.cluster.local"
  token    = data.kubernetes_secret.authentik-cred.data["PASSWORD"]
  insecure = true
}

provider "kubernetes" {}
