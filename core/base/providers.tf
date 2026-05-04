terraform {
  backend "kubernetes" {
    secret_suffix     = "core-base"
    namespace         = "terraform-states"
  }
}

provider "helm" {
  kubernetes = {
    in_cluster_config = true
  }
}