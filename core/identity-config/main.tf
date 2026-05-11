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
resource "kubernetes_secret" "authentik-cred" {
  metadata {
    name      = "authentik-cred"
    namespace = "terraform-states"
  }

  data = {
    PASSWORD = authentik_token.terraform_api.key
    USER     = "admin@jpruitt.dev"
  }

  type = "Opaque"
}
