// ghcr.io/sysadminsmedia/homebox
module "app_homebox" {
    source = "../../modules/service"

    depends_on = [ module.nfs_storage_subdir ]

    container_port = 7745
    dns_config = {
        cluster_fqdn = var.cluster_fqdn
        host_ip = local.primary_ingress_ip
        subdomain_name = "homebox"
    }
    environment = {
        HBOX_LOG_LEVEL = "info"
        HBOX_LOG_FORMAT = "text"
        TZ = "Europe/Helsinki"
    }
    image = {
        tag = "latest"
        uri = "ghcr.io/sysadminsmedia/homebox"
    }
    name = "homebox"
    namespace = kubernetes_namespace.business.metadata[0].name
    # run_as = {
    #     user = 99
    #     group = 100
    # }
    service_port = 80
    subdir_mounts = {
        data = {
            container_path = "/data"
            storage = "appdata"
            storage_request = "25Gi"
        }
    }
    tailscale = {
        hostname = "homebox"
        host_ip = local.primary_ingress_ip
        tailnet = var.tailscale_tailnet
    }
}
