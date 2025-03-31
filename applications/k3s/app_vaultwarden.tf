module "app_vaultwarden" {
    source = "../../modules/service2"

    depends_on = [ module.longhorn ]

    container_port = 80
    dns_config = {
        cluster_fqdn = var.cluster_fqdn
        host_ip = local.primary_ingress_ip
        subdomain_name = "vaultwarden"
    }
    # environment = {
    #     PGID = "100"
    #     PUID = "99"
    #     TZ = "Europe/Helsinki"
    # }
    image = {
        tag = "latest"
        uri = "vaultwarden/server"
    }
    longhorn_mounts = {
        data = {
            container_path = "/data"
            storage_request = "50Gi"
        }
    }
    name = "vaultwarden"
    namespace = kubernetes_namespace.security.metadata[0].name
    service_port = 80
    tailscale = {
        hostname = "vaultwarden"
        host_ip = local.primary_ingress_ip
        tailnet = var.tailscale_tailnet
    }
}
