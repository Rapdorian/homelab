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
  slug    = "samba"
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

resource "kubernetes_secret" "samba-cred" {
  metadata {
    name      = "samba-cred"
    namespace = kubernetes_namespace.samba.metadata[0].name
  }
  data = {
    USER_PASSWORD = random_password.samba.result
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
          image = "linuxserver/samba:latest"
          name  = "samba"

          env {
            name  = "TZ"
            value = "UTC"
          }

          env {
            name  = "USER_NAME"
            value = var.username
          }

          env {
            name  = "USER_PASSWORD"
            value = random_password.samba.result
          }

          env {
            name  = "USER_ID"
            value = "1000"
          }

          env {
            name  = "GROUP_ID"
            value = "1000"
          }

          env {
            name  = "SHARE_NAME"
            value = "PS2"
          }

          env {
            name  = "VERSION1"
            value = "yes"
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
            name       = "config"
            mount_path = "/config"
          }

          volume_mount {
            name       = "share"
            mount_path = "/storage"
          }
        }

        volume {
          name = "config"
          empty_dir {}
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
