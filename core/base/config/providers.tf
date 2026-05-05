terraform {
  backend "kubernetes" {
    secret_suffix     = "core-base-config"
    namespace         = "terraform-states"
  }
}

provider "helm" {
  kubernetes = {
    in_cluster_config = true
  }
}
