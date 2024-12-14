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
    source = "../../modules/service"

    depends_on = [ module.db_init_kimai, module.nfs_storage_subdir ]

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
    service_port = 80
    subdir_mounts = {
        data = {
            container_path = "/opt/kimai/var/data"
            storage = "appdata"
            storage_request = "20Gi"
        }
    }
    tailscale = {
        hostname = "kimai"
        host_ip = local.primary_ingress_ip
        tailnet = var.tailscale_tailnet
    }
}
