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

provider "postgresql" {
  host            = "postgresql.database.svc.cluster.local"
  port            = 5432
  database        = "postgres"
  username        = "postgres"
  password        = random_password.postgres_password.result
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

  postgres_password = random_password.postgres_password.result
}


module "apps" {
  source = "./apps"
  authentik_token = random_password.authentik_token.result
}

resource "postgresql_role" "app_user" {
  name = "app_user"
  login = true
  password = "password"
}
