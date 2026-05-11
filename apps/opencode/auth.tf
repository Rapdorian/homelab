# --- 1. DATA SOURCES ---
# We need to tell Terraform to LOOK UP these existing items in Authentik

data "authentik_flow" "default_authorization" {
  slug = "default-provider-authorization-implicit-consent"
}

resource "authentik_group" "users" {
  name = "authentik Admins"
  is_superuser = false
}

resource "authentik_provider_proxy" "simple_server_auth" {
  name               = "Simple Server Provider"
  external_host      = "https://myserver.example.com"
  mode               = "forward_single_auth"
  authorization_flow = data.authentik_flow.default_authorization.id
}

resource "authentik_application" "opencode_app" {
  name              = "OpenCode"
  slug              = "opencode"
  protocol_provider = authentik_provider_proxy.simple_server_auth.id
}

resource "authentik_policy_binding" "require_login" {
  target = authentik_application.opencode_app.uuid
  group  = authentik_group.users.id
  order  = 0
}