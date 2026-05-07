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

resource "kubernetes_config_map" "samba_smb_conf" {
  metadata {
    name      = "samba-smb-conf"
    namespace = kubernetes_namespace.samba.metadata[0].name
  }
  data = {
    "smb.conf" = <<-EOF
      [global]
         server string = PS2 Share
         netbios name = PS2SHARE
         server min protocol = NT1
         server max protocol = SMB3
         map to guest = never
         security = user
         log level = 1
         log file = /var/log/samba/log.%m
         max log size = 1000

         [PS2]
            path = /storage
            browsable = yes
            writable = yes
            guest ok = no
            read only = no
            create mask = 0777
            directory mask = 0777
            valid users = ${var.username}
    EOF
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
          image = "dperson/samba:latest"
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
            name       = "smb-conf"
            mount_path = "/etc/samba/smb.conf"
            sub_path   = "smb.conf"
          }

          volume_mount {
            name       = "share"
            mount_path = "/storage"
          }
        }

        volume {
          name = "smb-conf"
          config_map {
            name = kubernetes_config_map.samba_smb_conf.metadata[0].name
            items {
              key  = "smb.conf"
              path = "smb.conf"
            }
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
