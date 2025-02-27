module "tailscale_subnet" {
    source = "../../modules/tailscale-subnet"

    additional_cidrs = var.network_cidrs
    auth_key = var.tailscale_container_auth
    namespace = "default"
    longhorn_mounts = {
        tailscale = {
            container_path = "/var/lib/tailscale"
            storage_request = "5Gi"
        }
    }
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
