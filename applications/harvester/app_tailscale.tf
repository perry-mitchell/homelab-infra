module "tailscale_subnet" {
  source = "../../modules-harvester/tailscale-subnet"

  additional_cidrs = var.network_cidrs
  auth_key         = var.tailscale_container_auth
  hostname         = "tailscale-torrens"
  namespace        = "default"
  longhorn_mounts = {
    tailscale = {
      container_path  = "/var/lib/tailscale"
      storage_request = "5Gi"
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  replicas = local.deployments_enabled.network ? 1 : 0
}
