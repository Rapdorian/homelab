variable "cluster_ca_certificate" {
  type      = string
  sensitive = true
}

variable "cluster_host" {
  type      = string
  sensitive = false
}

variable "cluster_token" {
  type      = string
  sensitive = true
}

provider "helm" {
  kubernetes = {
    host                   = var.cluster_host
    cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
    token                  = var.cluster_token
  }
}

module "dbs" {
  source = "./db"
}
