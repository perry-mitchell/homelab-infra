module "app_kopia" {
    source = "../../modules/service"

    depends_on = [ kubernetes_namespace.backup, module.nfs_storage ]

    container_port = 51515
    dns_config = {
        cluster_fqdn = var.cluster_fqdn
        host_ip = local.primary_ingress_ip
        subdomain_name = "kopia"
    }
    environment = {
        TZ = "Europe/Helsinki"
        PUID = "99"
        PGID = "100"
        USERNAME = var.kopia_admin.username
        PASSWORD = var.kopia_admin.password
        KOPIA_PERSIST_CREDENTIALS_ON_CONNECT = "true"
    }
    image = {
        tag = "latest"
        uri = "ghcr.io/imagegenius/kopia"
    }
    mounts = {
        config = {
            container_path = "/config"
            storage = "appdata"
            storage_request = "1Gi"
        }
        cache = {
            container_path = "/cache"
            storage = "appdata"
            storage_request = "50Gi"
        }
        # logs = {
        #     container_path = "/app/logs"
        #     storage = "appdata"
        #     storage_request = "10Gi"
        # }
        repository = {
            container_path = "/local"
            storage = "backup"
            storage_request = "250Gi"
        }
        temp = {
            container_path = "/tmp"
            storage = "appdata"
            storage_request = "10Gi"
        }
    }
    name = "kopia"
    namespace = kubernetes_namespace.backup.metadata[0].name
    service_port = 80
    tailscale = {
        hostname = "kopia"
        host_ip = local.primary_ingress_ip
        tailnet = var.tailscale_tailnet
    }
}
