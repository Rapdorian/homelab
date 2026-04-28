resource "random_password" "password" {
  length = 16
  special = false
}

output "postgres_password" {
  value = random_password.password.result
}

resource "helm_release" "postgresql" {
	name = "postgresql"
	chart = "oci://registry-1.docker.io/bitnamicharts/postgresql"
	namespace = "database"
	create_namespace = true
  values = [ templatefile("${path.module}/postgresql.yml", {
    password = random_password.password.result
  }) ]
  wait = true
}
