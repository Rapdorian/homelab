data "authentik_flow" "default_authorization" {
  slug = "default-provider-authorization-implicit-consent"
}

data "authentik_flow" "default_invalidation" {
  slug = "default-provider-invalidation-flow"
}

# Proxy provider — forward_single covers the whole domain
resource "authentik_provider_proxy" "opencode" {
  name               = "OpenCode Provider"
  external_host      = "https://opencode.svc.jpruitt.dev"
  mode               = "forward_single"
  authorization_flow = data.authentik_flow.default_authorization.id
  invalidation_flow  = data.authentik_flow.default_invalidation.id
}

resource "authentik_application" "opencode" {
  name              = "OpenCode"
  slug              = "opencode"
  protocol_provider = authentik_provider_proxy.opencode.id
  group             = "apps"
}

# Re-use the existing kubernetes service connection created in core/identity
data "authentik_service_connection_kubernetes" "local" {
  name = "local-cluster"
}

# Embedded outpost — authentik manages the deployment automatically
resource "authentik_outpost" "proxy" {
  name               = "proxy-outpost"
  type               = "proxy"
  service_connection = data.authentik_service_connection_kubernetes.local.id
  protocol_providers = [
    authentik_provider_proxy.opencode.id
  ]

  config = jsonencode({
    authentik_host          = "https://auth.svc.jpruitt.dev"
    authentik_host_insecure = false
    log_level               = "info"
    docker_network          = null
    docker_map_ports        = true
    kubernetes_replicas     = 1
    kubernetes_namespace    = "authentik"
    kubernetes_ingress_annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure"
    }
    kubernetes_ingress_secret_name = "authentik-proxy-tls"
    kubernetes_service_type        = "ClusterIP"
  })
}

# Create the namespace explicitly so the Middleware CRD and helm release
# don't race — helm's create_namespace happens too late for the manifest resource.
resource "kubernetes_namespace" "adlc" {
  metadata {
    name = "adlc"
  }
}

# Traefik ForwardAuth middleware — lives in the adlc namespace so the
# IngressRoute in that namespace can reference it directly
resource "kubernetes_manifest" "traefik_forwardauth" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "authentik-forwardauth"
      namespace = "adlc"
    }
    spec = {
      forwardAuth = {
        address = "http://ak-outpost-proxy-outpost.authentik.svc.cluster.local:9000/outpost.goauthentik.io/auth/traefik"
        trustForwardHeader = true
        authResponseHeaders = [
          "X-authentik-username",
          "X-authentik-groups",
          "X-authentik-email",
          "X-authentik-name",
          "X-authentik-uid",
          "X-authentik-jwt",
          "X-authentik-meta-jwks",
          "X-authentik-meta-outpost",
          "X-authentik-meta-provider",
          "X-authentik-meta-app",
          "X-authentik-meta-version",
        ]
      }
    }
  }

  depends_on = [authentik_outpost.proxy, kubernetes_namespace.adlc]
}
