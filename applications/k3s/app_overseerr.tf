module "app_overseerr" {
    source = "../../modules/service2"

    depends_on = [ module.longhorn ]

    container_port = 5055
    dns_config = {
        cluster_fqdn = var.cluster_fqdn
        host_ip = local.primary_ingress_ip
        subdomain_name = "overseerr"
    }
    environment = {
        PGID = "100"
        PUID = "99"
        TZ = "Europe/Helsinki"
    }
    image = {
        tag = "latest"
        uri = "lscr.io/linuxserver/overseerr"
    }
    longhorn_mounts = {
        data = {
            container_path = "/config"
            storage_request = "10Gi"
        }
    }
    name = "overseerr"
    namespace = kubernetes_namespace.torrents.metadata[0].name
    replicas = 1
    service_port = 80
    tailscale = {
        hostname = "overseerr"
        host_ip = local.primary_ingress_ip
        tailnet = var.tailscale_tailnet
    }
}
