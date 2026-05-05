resource "kubernetes_manifest" "metallb_ip_pool" {
  manifest = {
    "apiVersion" = "metallb.io/v1beta1"
    "kind"       = "IPAddressPool"
    "metadata" = {
      "name"      = "k3s-lb-pool"
      "namespace" = "metallb-system"
    }
    "spec" = {
      "addresses" = [
        "10.0.1.50-10.0.1.255",
        "10.0.0.55/32"
      ]
    }
  }
}

resource "kubernetes_manifest" "metallb_l2_advertisement" {
  manifest = {
    "apiVersion" = "metallb.io/v1beta1"
    "kind"       = "L2Advertisement"
    "metadata" = {
      "name"      = "l2-advert"
      "namespace" = "metallb-system"
    }
    "spec" = {
      "ipAddressPools" = [
        "k3s-lb-pool"
      ]
    }
  }
}
