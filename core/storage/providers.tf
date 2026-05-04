terraform {
  backend "kubernetes" {
    secret_suffix     = "core-storage"
    namespace         = "terraform-states"
  }
}

provider "helm" {
  kubernetes = {
    in_cluster_config = true
  }
}