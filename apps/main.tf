module "grafana" {
  source = "./grafana"
}

module "pgweb" {
  source = "./pgweb-module"
}

module "prometheus" {
  source = "./prometheus-module"
}
