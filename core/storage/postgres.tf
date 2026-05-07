resource "random_password" "password" {
  length = 16
  special = false
}

resource "helm_release" "postgresql" {
	name = "postgresql"
	chart = "oci://registry-1.docker.io/bitnamicharts/postgresql"
	namespace = "database"
	create_namespace = true
  values = [ templatefile("${path.module}/postgres.yml", {
    password = random_password.password.result
  }) ]
  wait = true
}

# Create the Secret in the 'authentik' or 'default' namespace
resource "kubernetes_secret" "postgres-tokens" {
  metadata {
    name      = "postgres-cred"
    namespace = "terraform-states" 
  }

  data = {
    PASSWORD = random_password.password.result
    USER = "postgres"
  }

  type = "Opaque"
}