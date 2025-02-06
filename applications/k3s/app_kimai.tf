resource "random_password" "kimai_database_user" {
    length = 32
    special = false
}

module "db_init_kimai" {
    source = "../../modules/mysql-init"

    depends_on = [ module.db_mariadb ]

    create_database = "kimai"
    create_user = {
        password = random_password.kimai_database_user.result
        username = "kimai"
    }
    db_host = local.mariadb_service_hostname
    db_password = var.db_mariadb_root
    db_username = "root"
    grant_users = {
        "kimai" = "kimai"
    }
    name = "kimai"
}

module "app_kimai" {
    source = "../../modules/service2"

    depends_on = [ module.db_init_kimai, module.nfs_storage_export ]

    container_port = 8001
    dns_config = {
        cluster_fqdn = var.cluster_fqdn
        host_ip = local.primary_ingress_ip
        subdomain_name = "kimai"
    }
    environment = {
        TZ = "Europe/Helsinki"
        ADMINMAIL = var.kimai_admin.email
        ADMINPASS = var.kimai_admin.password
        DATABASE_URL = "mysql://kimai:${random_password.kimai_database_user.result}@${local.mariadb_service_hostname}:3306/kimai?charset=utf8mb4"
    }
    image = {
        tag = "apache"
        uri = "kimai/kimai2"
    }
    name = "kimai"
    namespace = kubernetes_namespace.business.metadata[0].name
    nfs_mounts = {
        data = {
            create_subdir = true
            container_path = "/opt/kimai/var/data"
            nfs_export = var.nfs_storage.appdata.export
            nfs_server = var.nfs_storage.appdata.host
            storage_request = "20Gi"
        }
    }
    replicas = 1
    service_port = 80
    tailscale = {
        hostname = "kimai"
        host_ip = local.primary_ingress_ip
        tailnet = var.tailscale_tailnet
    }
}
