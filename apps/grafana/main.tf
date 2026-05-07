terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.26.0"
    }
    authentik = {
      source  = "goauthentik/authentik"
      version = "2025.12.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0, < 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

data "authentik_flow" "default_auth" {
  slug = "default-provider-authorization-implicit-consent"
}

data "authentik_flow" "default_invalidation" {
  slug = "default-provider-invalidation-flow"
}

resource "random_password" "pg_password" {
  length  = 16
  special = true
}

resource "random_password" "client_id" {
  length  = 16
  special = false
}

resource "random_password" "client_secret" {
  length  = 50
  special = true
}

resource "postgresql_role" "grafana_user" {
  name     = "grafana_user"
  login    = true
  password = random_password.pg_password.result
}

resource "postgresql_database" "grafana_db" {
  name             = "grafana"
  owner            = postgresql_role.grafana_user.name
  lc_collate       = "en_US.UTF-8"
  connection_limit = -1
  allow_connections = true
}

resource "kubernetes_secret" "grafana_secret" {
  metadata {
    name      = "grafana-postgres-secret"
    namespace = "metric"
  }
  data = {
    "postgres-password"  = random_password.pg_password.result
    "auth-client-id"     = random_password.client_id.result
    "auth-client-secret" = random_password.client_secret.result
  }
}

resource "authentik_group" "gf_edit" {
  name = "Grafana Editors"
}

resource "authentik_group" "gf_admin" {
  name = "Grafana Admins"
}

resource "authentik_provider_oauth2" "grafana" {
  name               = "Grafana"
  client_id          = random_password.client_id.result
  client_secret      = random_password.client_secret.result
  authorization_flow = data.authentik_flow.default_auth.id
  invalidation_flow  = data.authentik_flow.default_invalidation.id

  allowed_redirect_uris = [
    {
      matching_mode = "regex"
      url           = ".*jpruitt.dev"
    }
  ]

  property_mappings = [
    "openid",
    "profile",
    "email"
  ]
}

resource "helm_release" "grafana" {
  name           = "grafana"
  chart          = "oci://ghcr.io/grafana-community/helm-charts/grafana"
  namespace      = "metric"
  create_namespace = true
  values         = [file("${path.module}/grafana.yml")]

  depends_on = [kubernetes_secret.grafana_secret]
}
