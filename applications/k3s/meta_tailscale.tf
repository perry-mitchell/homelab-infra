module "tailscale_subnet" {
    source = "../../modules/tailscale-subnet"

    additional_cidrs = var.network_cidrs
    auth_key = var.tailscale_container_auth
    storage = "appdata"
}

# module "tailscale_subnet-2" {
#     source = "../../modules/tailscale-subnet-2"

#     additional_cidrs = var.network_cidrs
#     auth_key = var.tailscale_container_auth
#     storage = "appdata"
# }

module "tailscale" {
    source = "../../modules/tailscale"

    oauth = {
      client_id = var.tailscale_oauth.client_id
      client_secret = var.tailscale_oauth.client_secret
    }
}
