terraform {
  backend "kubernetes" {
    secret_suffix     = "core-base-install"
    namespace         = "terraform-states"
  }
}

provider "helm" {
  kubernetes = {
    in_cluster_config = true
  }
}
