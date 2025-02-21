module "app_homebox" {
    source = "../../modules/service2"

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
    nfs_mounts = {
        data = {
            create_subdir = true
            container_path = "/data"
            nfs_export = var.nfs_storage.appdata.export
            nfs_server = var.nfs_storage.appdata.host
            storage_request = "25Gi"
        }
    }
    # replicas = 0
    service_port = 80
    tailscale = {
        hostname = "homebox"
        host_ip = local.primary_ingress_ip
        tailnet = var.tailscale_tailnet
    }
}
