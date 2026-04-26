terraform {
  backend "kubernetes" {
    secret_suffix     = "infra-state"
    namespace         = "terraform-states"
  }
}

terraform {
  required_providers {
    postgresql = {
      source = "cyrilgdn/postgresql"
      version = "1.26.0"
    }
  }
}

variable "pg_host" {
  type      = string
  sensitive = true
  default   = "postgresql.database.svc.cluster.local"
}

data "kubernetes_secret" "pg-secret" {
  metadata {
    name      = "postgresql"
    namespace = "database"
  }
  depends_on = [module.dbs]
}

provider "postgresql" {
  host            = var.pg_host
  port            = 5432
  database        = ""
  username        = "postgres"
  password        = data.kubernetes_secret.pg-secret.data["postgres-password"]
  sslmode         = "disable"
  connect_timeout = 15
}

variable "github_token" {
  type      = string
  sensitive = true
}

provider "helm" {
  kubernetes = {
    in_cluster_config = true
  }
}

module "dns" {
  source = "./dns"
}

module "dev-tools" {
  source = "./dev-tools"
  github_token = var.github_token
}

module "dbs" {
  source = "./dbs"

}


module "apps" {
  source = "./apps"
  authentik_token = random_password.authentik_token.result
}
