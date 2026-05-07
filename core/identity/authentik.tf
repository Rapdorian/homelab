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
      ldap_password = random_password.ldap_password.result
    })
  ]
}
