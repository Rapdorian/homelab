module "grafana" {
  source = "./grafana"

  depends_on = [module.prometheus]
}

module "pgweb" {
  source = "./pgweb-module"
}

module "prometheus" {
  source = "./prometheus-module"
}
