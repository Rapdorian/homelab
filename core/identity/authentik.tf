resource "random_password" "authentik_secret_key" {
  length  = 50
  special = false
}

resource "random_password" "authentik_token" {
  length  = 16
  special = true
}

resource "random_password" "ldap_password" {
  length  = 32
  special = false
}

resource "kubernetes_secret" "authentik-cred" {
  metadata {
    name      = "authentik-cred"
    namespace = "terraform-states" 
  }

  data = {
    PASSWORD = random_password.authentik_token.result
    USER = "admin@jpruitt.dev"
  }

  type = "Opaque"
}

resource "kubernetes_secret" "authentik-ldap-cred" {
  metadata {
    name      = "authentik-ldap-cred"
    namespace = "terraform-states"
  }

  data = {
    PASSWORD = random_password.ldap_password.result
  }

  type = "Opaque"
}

resource "random_password" "pg-password" {
  length  = 16
  special = true
}

resource "postgresql_role" "authentik_user" {
  name = "authentik_user"
  login = true
  password = random_password.pg-password.result
}

resource "postgresql_database" "authentik-db" {
  name = "authentik"
  owner = postgresql_role.authentik_user.name
  lc_collate = "en_US.UTF-8"
  connection_limit = -1
  allow_connections = true
}

resource "helm_release" "authentik" {
  name       = "authentik"
  repository = "https://charts.goauthentik.io"
  chart      = "authentik"
  namespace  = "authentik"
  create_namespace = true

  values = [
    templatefile("${path.module}/authentik.yml", {
      password = random_password.pg-password.result
      authentik_token = random_password.authentik_token.result
      secret_key = random_password.authentik_secret_key.result
    })
  ]
}

data "authentik_flow" "default-authentication-flow" {
  slug = "default-authentication-flow"

  depends_on = [helm_release.authentik]
}

data "authentik_flow" "default-invalidation-flow" {
  slug = "default-invalidation-flow"

  depends_on = [helm_release.authentik]
}

resource "authentik_provider_ldap" "samba" {
  name         = "samba-ldap"
  base_dn      = "dc=ldap,dc=goauthentik,dc=io"
  bind_flow    = data.authentik_flow.default-authentication-flow.id
  unbind_flow  = data.authentik_flow.default-invalidation-flow.id

  depends_on = [helm_release.authentik]
}

resource "authentik_service_connection_kubernetes" "local" {
  name  = "local-cluster"
  local = true

  depends_on = [helm_release.authentik]
}

resource "authentik_outpost" "ldap" {
  name             = "samba-ldap-outpost"
  type             = "ldap"
  protocol_providers = [
    authentik_provider_ldap.samba.id
  ]

  depends_on = [helm_release.authentik]
}

resource "kubernetes_deployment" "ldap_outpost" {
  metadata {
    name      = "authentik-ldap-outpost"
    namespace = "authentik"
    labels = {
      app = "authentik-ldap"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "authentik-ldap"
      }
    }

    template {
      metadata {
        labels = {
          app = "authentik-ldap"
        }
      }

      spec {
        container {
          name  = "ldap-outpost"
          image = "ghcr.io/goauthentik/ldap:2026.2.2"

          port {
            container_port = 3389
            protocol       = "TCP"
          }

          port {
            container_port = 6636
            protocol       = "TCP"
          }

          env {
            name  = "AUTHENTIK_HOST"
            value = "http://authentik-server.authentik.svc.cluster.local"
          }

          env {
            name  = "AUTHENTIK_TOKEN"
            value = random_password.authentik_token.result
          }

          env {
            name  = "AUTHENTIK_INSECURE"
            value = "true"
          }
        }
      }
    }
  }

  depends_on = [helm_release.authentik]
}

resource "kubernetes_service" "ldap_outpost" {
  metadata {
    name      = "authentik-ldap"
    namespace = "authentik"
  }

  spec {
    selector = {
      app = "authentik-ldap"
    }

    port {
      name        = "ldap"
      port        = 3389
      target_port = 3389
      protocol    = "TCP"
    }

    port {
      name        = "ldaps"
      port        = 6636
      target_port = 6636
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.ldap_outpost]
}

resource "authentik_user" "ldapservice" {
  username = "ldapservice"
  name     = "LDAP Service Account"
  type     = "service_account"

  depends_on = [helm_release.authentik]
}

resource "null_resource" "set_ldapservice_password" {
  triggers = {
    user_id = authentik_user.ldapservice.id
  }

  provisioner "local-exec" {
    command = <<-EOF
      curl -s -k -X POST \
        -H "Authorization: Bearer ${random_password.authentik_token.result}" \
        -H "Content-Type: application/json" \
        -d '{"password": "${random_password.ldap_password.result}"}' \
        "http://authentik-server.authentik.svc.cluster.local/api/v3/admin/users/${authentik_user.ldapservice.id}/set_password/"
    EOF
  }

  depends_on = [authentik_user.ldapservice]
}

data "authentik_group" "samba_users" {
  name = "Samba Users"

  depends_on = [helm_release.authentik]
}

resource "authentik_group" "samba_admins" {
  name = "Samba Admins"

  depends_on = [helm_release.authentik]
}
