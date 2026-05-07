terraform {
  backend "kubernetes" {
    secret_suffix     = "core-base-config"
    namespace         = "terraform-states"
  }

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "helm" {
  kubernetes = {
    in_cluster_config = true
  }
}
