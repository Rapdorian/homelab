# Look up the akadmin user created by authentik bootstrap
data "authentik_user" "akadmin" {
  username = "akadmin"
}

# Create a persistent, non-expiring API token for Terraform
resource "authentik_token" "terraform_api" {
  identifier   = "terraform-api-token"
  user         = data.authentik_user.akadmin.id
  intent       = "api"
  expiring     = false
  retrieve_key = true
}

# Overwrite the authentik-cred secret with the persistent token.
# After this runs, core/identity no longer needs to be re-applied
# to recover API access — this token survives authentik pod restarts.
# Write the persistent token to a separate secret so it doesn't
# conflict with the bootstrap token secret owned by core/identity.
# apps/ reads from this secret going forward.
resource "kubernetes_secret" "authentik-persistent-cred" {
  metadata {
    name      = "authentik-persistent-cred"
    namespace = "terraform-states"
  }

  data = {
    PASSWORD = authentik_token.terraform_api.key
    USER     = "admin@jpruitt.dev"
  }

  type = "Opaque"
}
