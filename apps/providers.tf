terraform {
  backend "kubernetes" {
    secret_suffix     = "apps"
    namespace         = "terraform-states"
  }

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0, < 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.26.0"
    }
    authentik = {
      source  = "goauthentik/authentik"
      version = "2025.12.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

data "kubernetes_secret" "pg-cred" {
  metadata {
    name      = "postgres-cred"
    namespace = "terraform-states"
  }
}

data "kubernetes_secret" "authentik-cred" {
  metadata {
    name      = "authentik-persistent-cred"
    namespace = "terraform-states"
  }
}

provider "postgresql" {
  host            = "postgresql.database.svc.cluster.local"
  port            = 5432
  database        = ""
  username        = data.kubernetes_secret.pg-cred.data["USER"]
  password        = data.kubernetes_secret.pg-cred.data["PASSWORD"]
  sslmode         = "disable"
  connect_timeout = 15
}

provider "authentik" {
  url   = "https://auth.svc.jpruitt.dev"
  token = data.kubernetes_secret.authentik-cred.data["PASSWORD"]
}
