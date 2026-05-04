terraform {
  required_providers {
    postgresql = {
      source = "cyrilgdn/postgresql"
      version = "1.26.0"
    }
  }
}

# Look up the secret created by the identity layer
data "kubernetes_secret" "pg-cred" {
  metadata {
    name      = "postgres-auth"
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