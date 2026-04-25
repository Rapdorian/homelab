variable "authentik_token" {
  type      = string
  sensitive = true
}

# resource "helm_release" "authentik" {
#   name       = "authentik"
#   repository = "https://charts.goauthentik.io"
#   chart      = "authentik"
#   namespace  = "authentik"
#   create_namespace = true
# 
#   values = [
#     templatefile("${path.module}/authentik.yml", {
#       password = "test"
#       authentik_token = var.authentik_token
#     })
#   ]
# }
