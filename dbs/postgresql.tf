resource "helm_release" "postgresql" {
	name = "postgresql"
	chart = "oci://registry-1.docker.io/bitnamicharts/postgresql"
	namespace = "database"
	create_namespace = true
  #values = [ file("${path.module}/postgresql.yml") ]
  wait = true
  # depends_on = [kubernetes_secret.pg-secret]
}
