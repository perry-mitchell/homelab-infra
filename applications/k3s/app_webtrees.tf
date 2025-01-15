locals {
  webtrees_url = "http://webtrees.${var.tailscale_tailnet}"
}

resource "random_password" "webtrees_database_user" {
    length = 32
    special = false
}

module "db_init_webtrees" {
    source = "../../modules/mysql-init"

    depends_on = [ module.db_mariadb ]

    create_database = "webtrees"
    create_user = {
        password = random_password.webtrees_database_user.result
        username = "webtrees"
    }
    db_host = local.mariadb_service_hostname
    db_password = var.db_mariadb_root
    db_username = "root"
    grant_users = {
        "webtrees" = "webtrees"
    }
    name = "webtrees"
}

module "app_webtrees" {
    source = "../../modules/service"

    depends_on = [ module.db_init_webtrees, module.nfs_storage_subdir ]

    container_port = 80
    dns_config = {
        cluster_fqdn = var.cluster_fqdn
        host_ip = local.primary_ingress_ip
        subdomain_name = "webtrees"
    }
    environment = {
        BASE_URL = local.webtrees_url
        DB_HOST = local.mariadb_service_hostname
        DB_NAME = "webtrees"
        DB_PASS = random_password.webtrees_database_user.result
        DB_PORT = 3306
        DB_USER = "webtrees"
        PRETTY_URLS = "yes"
        WT_EMAIL = var.webtrees_admin.email
        WT_NAME = var.webtrees_admin.name
        WT_PASS = var.webtrees_admin.password
        WT_USER = var.webtrees_admin.username
    }
    image = {
        tag = "latest"
        uri = "nathanvaughn/webtrees"
    }
    name = "webtrees"
    namespace = kubernetes_namespace.family.metadata[0].name
    service_port = 80
    subdir_mounts = {
        data = {
            container_path = "/var/www/webtrees/data"
            storage = "appdata"
            storage_request = "10Gi"
        }
    }
    tailscale = {
        hostname = "webtrees"
        host_ip = local.primary_ingress_ip
        tailnet = var.tailscale_tailnet
    }
}
