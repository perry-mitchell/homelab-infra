module "app_kopia" {
    source = "../../modules/service2"

    depends_on = [ kubernetes_namespace.backup, module.nfs_storage_subdir ]

    container_port = 51515
    dns_config = {
        cluster_fqdn = var.cluster_fqdn
        host_ip = local.primary_ingress_ip
        subdomain_name = "kopia"
    }
    environment = {
        TZ = "Europe/Helsinki"
        PUID = "0"
        PGID = "0"
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
    nfs_mounts = {
        config = {
            create_subdir = true
            container_path = "/config"
            nfs_export = var.nfs_storage.appdata.export
            nfs_server = var.nfs_storage.appdata.host
            storage_request = "1Gi"
        }
        cache = {
            create_subdir = true
            container_path = "/cache"
            nfs_export = var.nfs_storage.appdata.export
            nfs_server = var.nfs_storage.appdata.host
            storage_request = "50Gi"
        }
        repository = {
            create_subdir = true
            container_path = "/local"
            nfs_export = var.nfs_storage.backup.export
            nfs_server = var.nfs_storage.backup.host
            storage_request = "250Gi"
        }
        temp = {
            create_subdir = true
            container_path = "/tmp"
            nfs_export = var.nfs_storage.appdata.export
            nfs_server = var.nfs_storage.appdata.host
            storage_request = "10Gi"
        }
        # Backup sources
        appdata = {
            create_subdir = false
            container_path = "/source/appdata"
            nfs_export = var.nfs_storage_backup.appdata.export
            nfs_server = var.nfs_storage_backup.appdata.host
            read_only = true
            storage_request = "1Ti"
        }
        photos = {
            create_subdir = false
            container_path = "/source/photos"
            nfs_export = var.nfs_storage_backup.photos.export
            nfs_server = var.nfs_storage_backup.photos.host
            read_only = true
            storage_request = "1Ti"
        }
    }
    replicas = 1
    run_as = {
      user = 0
      group = 0
    }
    service_port = 80
    tailscale = {
        hostname = "kopia"
        host_ip = local.primary_ingress_ip
        tailnet = var.tailscale_tailnet
    }
}
