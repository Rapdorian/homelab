resource "random_password" "pg-gf-password" {
  length  = 16
  special = true
}

resource "postgresql_role" "grafana-user" {
  name = "grafana_user"
  login = true
  password = random_password.pg-gf-password.result
}

resource "postgresql_database" "grafana-db" {
  name = "grafana"
  owner = postgresql_role.grafana-user.name
  lc_collate = "en_US.UTF-8"
  connection_limit = -1
  allow_connections = true
}

resource "kubernetes_secret" "grafana-postgres-secret" {
  metadata {
    name      = "grafana-postgres-secret"
    namespace = "metric"
  }
  data = {
    password = random_password.pg-gf-password.result
  }
}

resource "helm_release" "grafana" {
	name = "grafana"
	chart = "oci://ghcr.io/grafana-community/helm-charts/grafana"
	namespace = "metric"
	create_namespace = true
	values = [ file("${path.module}/grafana.yml") ]
}
