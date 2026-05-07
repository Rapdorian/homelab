terraform {
  backend "kubernetes" {
    secret_suffix     = "core-identity"
    namespace         = "terraform-states"
  }

  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = ">= 2024.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0, < 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.26.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Look up the secret created by the storage layer
data "kubernetes_secret" "pg-cred" {
  metadata {
    name      = "postgres-cred"
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
  url      = "http://authentik-server.authentik.svc.cluster.local"
  token    = random_password.authentik_token.result
  insecure = true
}
