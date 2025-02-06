resource "random_password" "nextcloud_database_user" {
    length = 32
    special = false
}

module "db_init_nextcloud" {
    source = "../../modules/mysql-init"

    depends_on = [ module.db_mariadb ]

    create_database = "nextcloud"
    create_user = {
        password = random_password.nextcloud_database_user.result
        username = "nextcloud"
    }
    db_host = local.mariadb_service_hostname
    db_password = var.db_mariadb_root
    db_username = "root"
    grant_users = {
        "nextcloud" = "nextcloud"
    }
    name = "nextcloud"
}

module "app_nextcloud" {
    source = "../../modules/service2"

    depends_on = [ module.db_init_nextcloud, module.nfs_storage_export ]

    container_port = 80
    dns_config = {
        cluster_fqdn = var.cluster_fqdn
        host_ip = local.primary_ingress_ip
        subdomain_name = "nextcloud"
    }
    environment = {
        TZ = "Europe/Helsinki"
        MYSQL_DATABASE = "nextcloud"
        MYSQL_USER = "nextcloud"
        MYSQL_PASSWORD = random_password.nextcloud_database_user.result
        MYSQL_HOST = local.mariadb_service_hostname
        REDIS_HOST = local.redis_service_hostname
        REDIS_HOST_PORT = "6379"
        REDIS_HOST_PASSWORD = var.db_redis_root
        REDIS_DB_INDEX = "${local.redis_db_reservations.nextcloud}"
    }
    image = {
        tag = "production-apache"
        uri = "nextcloud"
    }
    name = "nextcloud"
    namespace = kubernetes_namespace.family.metadata[0].name
    nfs_mounts = {
        data = {
            create_subdir = true
            container_path = "/var/www/html/data"
            nfs_export = var.nfs_storage.appdata.export
            nfs_server = var.nfs_storage.appdata.host
            storage_request = "1Ti"
        }
        config = {
            create_subdir = true
            container_path = "/var/www/html/config"
            nfs_export = var.nfs_storage.appdata.export
            nfs_server = var.nfs_storage.appdata.host
            storage_request = "5Gi"
        }
        customapps = {
            create_subdir = true
            container_path = "/var/www/html/custom_apps"
            nfs_export = var.nfs_storage.appdata.export
            nfs_server = var.nfs_storage.appdata.host
            storage_request = "10Gi"
        }
    }
    service_port = 80
    tailscale = {
        hostname = "nextcloud"
        host_ip = local.primary_ingress_ip
        tailnet = var.tailscale_tailnet
    }
}
