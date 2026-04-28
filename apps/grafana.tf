data "kubernetes_secret" "grafana-auth-client-secret" {
  metadata {
    name      = "grafana-auth-client-secret"
    namespace = "metric"
  }
}

resource "helm_release" "grafana" {
	name = "grafana"
	chart = "oci://ghcr.io/grafana-community/helm-charts/grafana"
	namespace = "metric"
	create_namespace = true
	values = [ file("${path.module}/grafana.yml") ]
}
