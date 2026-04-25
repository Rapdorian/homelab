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

variable "authentik_token" {
  type      = string
  sensitive = true
}

provider "helm" {
  kubernetes = {
    in_cluster_config = true
  }
}

module "dns" {
  source = "./dns"
}


module "dev-tools" {
  source = "./dev-tools"
  github_token = var.github_token
}

module "apps" {
  source = "./apps"
  authentik_token = var.authentik_token
}
