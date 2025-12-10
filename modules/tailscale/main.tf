resource "kubernetes_namespace" "tailscale" {
  metadata {
    name = "tailscale"
  }
}

# Tailscale versions:
#   https://tailscale.com/changelog

resource "helm_release" "tailscale" {
  name      = "tailscale-operator"
  namespace = resource.kubernetes_namespace.tailscale.metadata[0].name

  repository = "https://pkgs.tailscale.com/helmcharts"
  chart      = "tailscale-operator"
  version    = "1.90.9"
  wait       = true

  set {
    name  = "oauth.clientId"
    value = var.oauth.client_id
  }

  set {
    name  = "oauth.clientSecret"
    value = var.oauth.client_secret
  }
}
