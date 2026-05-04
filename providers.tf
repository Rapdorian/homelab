terraform {
  backend "kubernetes" {
    secret_suffix     = "infra-state"
    namespace         = "terraform-states"
  }
  required_providers {
    postgresql = {
      source = "cyrilgdn/postgresql"
      version = "1.26.0"
    }
    authentik = {
      source  = "goauthentik/authentik"
      version = "2025.12.0" # Use the version matching your authentik instance
    }
  }
}

provider "helm" {
  kubernetes = {
    in_cluster_config = true
  }
}

resource "time_sleep" "wait_for_authentik" {
  depends_on = [module.auth]
  create_duration = "60s"
}

provider "authentik" {
  url   = "http://authentik-server.authentik.svc.cluster.local"
  token = module.auth.authentik_token
  alias = "initialized"
}

provider "postgresql" {
  host            = "postgresql.database.svc.cluster.local"
  port            = 5432
  database        = ""
  username        = "postgres"
  password        = module.dbs.postgres_password
  sslmode         = "disable"
  connect_timeout = 15
}
