resource "authentik_provider_proxy" "simple_server_auth" {
  name               = "Opencode provider"
  external_host      = "https://opencode.svc.jpruitt.dev"
  mode               = "forward_single_auth"
  authorization_flow = data.authentik_flow.default_authorization.id
}

resource "authentik_application" "opencode-app" {
  name              = "Opencode"
  slug              = "opencode"
  protocol_provider = authentik_provider_proxy.simple_server_auth.id
  group             = "Dev Tools"
}

resource "authentik_policy_binding" "require_login" {
  target = authentik_application.opencode_app.uuid
  group  = data.authentik_group.users.id # Restrict to 'users' group
  order  = 0
}
