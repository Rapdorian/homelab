resource "kubernetes_namespace" "external_dns" {
  metadata {
    name = "external-dns"
  }
}

resource "kubernetes_config_map" "coredns_config" {
  metadata {
    name      = "coredns-external-config"
    namespace = kubernetes_namespace.external_dns.metadata[0].name
  }

  data = {
    "Corefile"   = file("${path.module}/Corefile")
    "jpruitt.db" = file("${path.module}/jpruitt.db")
  }
}

resource "kubernetes_deployment" "coredns_external" {
  metadata {
    name      = "coredns-external"
    namespace = kubernetes_namespace.external_dns.metadata[0].name
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "coredns-external"
      }
    }

    template {
      metadata {
        labels = {
          app = "coredns-external"
        }
      }

      spec {
        container {
          name  = "coredns"
          image = "coredns/coredns:latest"
          args  = ["-conf", "/etc/coredns/Corefile"]

          port {
            container_port = 53
            name           = "dns-udp"
            protocol       = "UDP"
          }

          port {
            container_port = 53
            name           = "dns-tcp"
            protocol       = "TCP"
          }

          volume_mount {
            name       = "config-volume"
            mount_path = "/etc/coredns"
            read_only  = true
          }
        }

        volume {
          name = "config-volume"
          config_map {
            name = kubernetes_config_map.coredns_config.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "coredns_service" {
  metadata {
    name      = "coredns-external-svc"
    namespace = kubernetes_namespace.external_dns.metadata[0].name
    annotations = {
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
