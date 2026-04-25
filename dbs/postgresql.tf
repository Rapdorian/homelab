variable "postgres_password" {
  type      = string
  sensitive = true
}

resource "random_password" "postgres_password" {
  length   = 16
  special = true
}

resource "kubernetes_secret" "pg-secret" {
  metadata {
    name      = "pg-secret"
    namespace = "database"
  }

  data = {
    postgres-password = random_password.postgres_password.result
  }
  
  type = "Opaque"
}

resource "helm_release" "postgresql" {
	name = "postgresql"
	chart = "oci://registry-1.docker.io/bitnamicharts/postgresql"
	namespace = "database"
	create_namespace = true
	values = [ file("${path.module}/postgresql.yml") ]
}
