resource "helm_release" "pgweb" {
	name = "pgweb"
	repository = "https://charts.ectobit.com"
	chart = "pgweb"
	namespace = "database"
	create_namespace = true
  values = [ file("${path.module}/pgweb.yml") ]
}
