module "app_z2m" {
    source = "../../modules/service"

    depends_on = [ module.nfs_storage_subdir ]

    container_port = 8080
    dns_config = {
        cluster_fqdn = var.cluster_fqdn
        host_ip = local.primary_ingress_ip
        subdomain_name = "z2m"
    }
    environment = {
      TZ = "Europe/Helsinki"
    }
    image = {
        tag = "latest"
        uri = "koenkk/zigbee2mqtt"
    }
    name = "z2m"
    namespace = kubernetes_namespace.smart_home.metadata[0].name
    service_port = 80
    subdir_mounts = {
        data = {
            container_path = "/app/data"
            storage = "appdata"
            storage_request = "15Gi"
        }
    }
    tailscale = {
        hostname = "z2m"
        host_ip = local.primary_ingress_ip
        tailnet = var.tailscale_tailnet
    }
}
