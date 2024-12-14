module "app_kopia" {
    source = "../../modules/service"

    depends_on = [ kubernetes_namespace.backup, module.nfs_storage_subdir ]

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
    name = "kopia"
    namespace = kubernetes_namespace.backup.metadata[0].name
    root_mounts = {
        appdata = {
            container_path = "/source/appdata"
            nfs_export = var.nfs_storage.appdata.export
            nfs_server = var.nfs_storage.appdata.host
            read_only = true
            storage_name = "k3s-root"
            storage_request = "10Gi"
        }
        # for name, mount in var.nfs_storage : name => {
        #     container_path = "/source/${name}"
        #     nfs_export = mount.export
        #     nfs_server = mount.host
        #     read_only = true
        #     storage_name = "k3s-root"
        #     storage_request = "10Gi"
        # }
    }
    service_port = 80
    subdir_mounts = {
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
    tailscale = {
        hostname = "kopia"
        host_ip = local.primary_ingress_ip
        tailnet = var.tailscale_tailnet
    }
}
