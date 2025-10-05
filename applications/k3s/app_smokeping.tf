module "app_smokeping" {
    source = "../../modules/service2"

    depends_on = [ module.nfs_storage_export ]

    container_port = 80
    dns_config = {
        cluster_fqdn = var.cluster_fqdn
        host_ip = local.primary_ingress_ip
        subdomain_name = "smokeping"
    }
    environment = {
        PGID = "100"
        PUID = "99"
        TZ = "Europe/Helsinki"
    }
    files = {
        "/config/Targets" = file("${path.module}/config/smokeping/Targets")
    }
    image = {
        tag = "latest"
        uri = "lscr.io/linuxserver/smokeping"
    }
    longhorn_mounts = {
        harvester-migration = {
            container_path = "/data2"
            storage_request = "5Gi"
        }
    }
    name = "smokeping"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    nfs_mounts = {
        data = {
            create_subdir = true
            container_path = "/data"
            nfs_export = var.nfs_storage.appdata.export
            nfs_server = var.nfs_storage.appdata.host
            storage_request = "5Gi"
        }
    }
    replicas = 0
    service_port = 80
    tailscale = {
        hostname = "smokeping"
        host_ip = local.primary_ingress_ip
        tailnet = var.tailscale_tailnet
    }
}
