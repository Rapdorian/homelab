resource "helm_release" "prometheus" {
	name = "prometheus"
	chart = "oci://ghcr.io/prometheus-community/charts/prometheus"
	namespace = "metric"
	create_namespace = true
}
