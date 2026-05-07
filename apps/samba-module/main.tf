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

data "kubernetes_secret" "authentik_ldap" {
  metadata {
    name      = "authentik-ldap-cred"
    namespace = "terraform-states"
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
         passdb backend = ldapsam:ldap://authentik-server.authentik.svc.cluster.local
         ldap suffix = dc=goauthentik,dc=io
         ldap user suffix = ou=users
         ldap group suffix = ou=groups
         ldap admin dn = cn=ldapservice,ou=users,dc=goauthentik,dc=io
         ldap ssl = off
         ldap passwd sync = yes
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
            valid users = @Samba Users
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
        init_container {
          image   = "dperson/samba"
          name    = "init-ldap"
          command = ["/bin/sh", "-c"]
          args = [
            "cp /etc/samba/smb.conf.orig /etc/samba/smb.conf && smbpasswd -w ${data.kubernetes_secret.authentik_ldap.data["PASSWORD"]}"
          ]
          env {
            name  = "TZ"
            value = "UTC"
          }
          volume_mount {
            name       = "samba-config"
            mount_path = "/etc/samba"
          }
          volume_mount {
            name       = "smb-conf-source"
            mount_path = "/etc/samba/smb.conf.orig"
            sub_path   = "smb.conf"
          }
        }

        container {
          image = "dperson/samba"
          name  = "samba"

          env {
            name  = "TZ"
            value = "UTC"
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
            name       = "samba-config"
            mount_path = "/etc/samba"
          }

          volume_mount {
            name       = "share"
            mount_path = "/storage"
          }
        }

        volume {
          name = "smb-conf-source"
          config_map {
            name = kubernetes_config_map.samba_smb_conf.metadata[0].name
          }
        }

        volume {
          name = "samba-config"
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
