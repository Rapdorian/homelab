variable "authentik_token" {
  type      = string
  sensitive = true
}

resource "helm_release" "authentik" {
  name       = "authentik"
  repository = "https://charts.goauthentik.io"
  chart      = "authentik"
  namespace  = "authentik"
  create_namespace = true

  # Essential values for a basic installation
  set = [
    {
      name  = "authentik.secret_key"
      value = var.authentik_token
    }, {
      name  = "postgresql.enabled"
      value = "false"
    }, {
      name  = "redis.enabled"
      value = "false"
    }
  ]
}
