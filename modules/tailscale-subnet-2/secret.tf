resource "kubernetes_secret" "tailscale_auth" {
    metadata {
        name = "tailscale-auth-a"
    }

    data = {
        TS_AUTHKEY = var.auth_key
    }

    type = "Opaque"
}
