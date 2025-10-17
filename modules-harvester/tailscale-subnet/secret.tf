resource "kubernetes_secret" "tailscale_auth" {
  metadata {
    name      = "tailscale-auth"
    namespace = var.namespace
  }

  data = {
    TS_AUTHKEY = var.auth_key
  }

  type = "Opaque"

  lifecycle {
    ignore_changes = [
      data
    ]
  }
}
