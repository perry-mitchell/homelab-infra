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
    longhorn_mounts = {
        mysql = {
            container_path = "/var/lib/mysql"
            storage_request = "50Gi"
        }
    }
    name = local.mariadb_service_name
    namespace = kubernetes_namespace.datasources.metadata[0].name
    replicas = 1
    service_port = 3306
}
