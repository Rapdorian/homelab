resource "random_password" "authentik_token" {
  length  = 16
  special = true
}

output "authentik_token" {
  value = random_password.authentik_token.result
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
    })
  ]
}
