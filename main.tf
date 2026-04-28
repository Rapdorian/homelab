variable "github_token" {
  type      = string
  sensitive = true
}

module "dns" {
  source = "./dns"
}

module "dev-tools" {
  source = "./dev-tools"
  github_token = var.github_token
}

module "dbs" {
  source = "./dbs"
}

module "auth" {
  source = "./auth"
  depends_on = [ module.dbs ]
}

module "apps" {
  source = "./apps"
  depends_on = [ module.dbs ]
}
