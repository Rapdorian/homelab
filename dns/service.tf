resource "kubernetes_service" "coredns_service" {
  metadata {
    name      = "coredns-external-svc"
    namespace = kubernetes_namespace.external_dns.metadata[0].name
    annotations = {
      # The Static IP for your network
      "metallb.universe.tf/loadBalancerIPs" = "10.0.1.51"
    }
  }

  spec {
    selector = {
      app = "coredns-external"
    }

    port {
      name     = "dns-udp"
      port     = 53
      protocol = "UDP"
    }

    port {
      name     = "dns-tcp"
      port     = 53
      protocol = "TCP"
    }

    type = "LoadBalancer"
  }
}
