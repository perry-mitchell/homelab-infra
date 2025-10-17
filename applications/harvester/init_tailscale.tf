module "tailscale" {
  source = "../../modules/tailscale"

  oauth = {
    client_id     = var.tailscale_oauth.client_id
    client_secret = var.tailscale_oauth.client_secret
  }
}
