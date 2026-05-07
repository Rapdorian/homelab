variable "share_size" {
  type    = string
  default = "50Gi"
}

variable "username" {
  type    = string
  default = "ps2"
}

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    authentik = {
      source  = "goauthentik/authentik"
      version = "2025.12.0"
    }
  }
}

resource "authentik_group" "samba_users" {
  name = "Samba Users"
}

resource "authentik_application" "samba" {
  name    = "Samba Share"
  slug    = "samba-share"
  group   = "apps"
}

resource "random_password" "samba" {
  length  = 16
  special = false
}

resource "kubernetes_namespace" "samba" {
  metadata {
    name = "samba"
  }
}

resource "kubernetes_persistent_volume_claim" "samba_share" {
  wait_until_bound = false
  metadata {
    name      = "samba-share"
    namespace = kubernetes_namespace.samba.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.share_size
      }
    }
  }
}

resource "kubernetes_deployment" "samba" {
  metadata {
    name      = "samba"
    namespace = kubernetes_namespace.samba.metadata[0].name
    labels = {
      app = "samba"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "samba"
      }
    }

    template {
      metadata {
        labels = {
          app = "samba"
        }
      }

      spec {
        container {
          image = "dperson/samba"
          name  = "samba"

          env {
            name  = "TZ"
            value = "UTC"
          }

          env {
            name  = "WORKGROUP"
            value = "WORKGROUP"
          }

          env {
            name  = "USER"
            value = "${var.username};${random_password.samba.result}"
          }

          env {
            name  = "SHARE"
            value = "PS2;/storage;yes;no;no;${var.username}"
          }

          port {
            container_port = 139
            protocol       = "TCP"
          }

          port {
            container_port = 445
            protocol       = "TCP"
          }

          port {
            container_port = 137
            protocol       = "UDP"
          }

          port {
            container_port = 138
            protocol       = "UDP"
          }

          volume_mount {
            name       = "share"
            mount_path = "/storage"
          }
        }

        volume {
          name = "share"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.samba_share.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "samba" {
  metadata {
    name      = "samba"
    namespace = kubernetes_namespace.samba.metadata[0].name
  }

  spec {
    type = "LoadBalancer"

    selector = {
      app = kubernetes_deployment.samba.spec[0].template[0].metadata[0].labels.app
    }

    port {
      name        = "netbios-ns"
      port        = 137
      target_port = 137
      protocol    = "UDP"
    }

    port {
      name        = "netbios-dgm"
      port        = 138
      target_port = 138
      protocol    = "UDP"
    }

    port {
      name        = "netbios-ssn"
      port        = 139
      target_port = 139
      protocol    = "TCP"
    }

    port {
      name        = "microsoft-ds"
      port        = 445
      target_port = 445
      protocol    = "TCP"
    }
  }

  depends_on = [kubernetes_deployment.samba]
}
