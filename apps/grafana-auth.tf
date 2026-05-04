resource "authentik_group" "gf-edit" {
  name = "Grafana Editors"
}

resource "authentik_group" "gf-admin" {
  name = "Grafana Admins"
}

resource "authentik_provider_oauth2" "grafana" {
  name               = "Grafana"
  client_id          = random_password.gf-client-id.result
  client_secret      = random_password.gf-client-secret.result
  authorization_flow = data.authentik_flow.default_auth.id
  invalidation_flow  = data.authentik_flow.default_invalidation.id
  
  allowed_redirect_uris = [
    {
      matching_mode = "regex",
      url           = ".*jpruitt.dev",
    }
  ]

  property_mappings = [
    "openid",
    "profile",
    "email"
  ]
}

resource "random_password" "gf-client-id" {
	length = 16
	special = false
}

resource "random_password" "gf-client-secret" {
	length = 50
	special = true
}
