terraform {
  backend "kubernetes" {
    secret_suffix     = "infra-state"
    namespace         = "terraform-states"
  }
}

variable "github_token" {
  type      = string
  sensitive = true
}

provider "helm" {
  kubernetes = {
    in_cluster_config = true
  }
}

module "dbs" {
  source = "./db"
}

module "dev-tools" {
  source = "./dev-tools"
  github_token = var.github_token
}
