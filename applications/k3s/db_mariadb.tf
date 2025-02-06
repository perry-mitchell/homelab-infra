module "db_mariadb" {
    source = "../../modules/service2"

    depends_on = [ module.nfs_storage_subdir ]

    container_port = 3306
    environment = {
        MARIADB_ROOT_PASSWORD = var.db_mariadb_root
        TZ = "Europe/Helsinki"
    }
    image = {
        tag = "latest"
        uri = "mariadb"
    }
    name = local.mariadb_service_name
    namespace = kubernetes_namespace.datasources.metadata[0].name
    nfs_mounts = {
        mysql = {
            create_subdir = true
            container_path = "/var/lib/mysql"
            nfs_export = var.nfs_storage.appdata.export
            nfs_server = var.nfs_storage.appdata.host
            storage = "appdata"
            storage_request = "50Gi"
        }
    }
    service_port = 3306
}
