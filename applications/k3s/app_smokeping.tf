module "app_smokeping" {
    source = "../../modules/service"

    depends_on = [ module.nfs_storage_subdir ]

    container_port = 80
    dns_config = {
        cluster_fqdn = var.cluster_fqdn
        host_ip = local.primary_ingress_ip
        subdomain_name = "smokeping"
    }
    files = {
        "/config/Targets" = file("${path.module}/config/smokeping/Targets")
    }
    image = {
        tag = "latest"
        uri = "lscr.io/linuxserver/smokeping"
    }
    name = "smokeping"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    service_port = 80
    subdir_mounts = {
        data = {
            container_path = "/data"
            storage = "appdata"
            storage_request = "5Gi"
        }
    }
    tailscale = {
        hostname = "smokeping"
        host_ip = local.primary_ingress_ip
        tailnet = var.tailscale_tailnet
    }
}
