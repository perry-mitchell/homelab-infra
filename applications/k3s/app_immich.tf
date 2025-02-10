locals {
    immich_tag = "v1.126.1"
}

resource "random_password" "immich_database_user" {
    length = 32
    special = false
}

module "db_init_immich" {
    source = "../../modules/postgres-init"

    depends_on = [ module.db_postgres_pgvecto_rs ]

    create_database = "immich"
    create_user = {
        password = random_password.immich_database_user.result
        username = "immich"
    }
    db_host = local.postgres_pgvecto_rs_service_hostname
    db_password = var.db_postgres_pgvecto_rs_root
    db_username = "root"
    extra_sql_lines = [
        "ALTER USER immich WITH SUPERUSER"
    ]
    name = "immich"
}

module "app_immich_ml" {
    source = "../../modules/service"

    depends_on = [ module.db_init_immich, module.nfs_storage_subdir ]

    container_port = 3003
    environment = {
        IMMICH_HOST = "0.0.0.0"
        IMMICH_PORT = "3003"
        TZ = "Europe/Helsinki"
    }
    image = {
        tag = local.immich_tag
        uri = "ghcr.io/immich-app/immich-machine-learning"
    }
    name = "immich-ml"
    namespace = kubernetes_namespace.family.metadata[0].name
    service_port = 3003
    subdir_mounts = {
        "model-cache" = {
            container_path = "/cache"
            storage = "appdata"
            storage_request = "100Gi"
        }
    }
}

module "app_immich" {
    source = "../../modules/service"

    depends_on = [ module.db_init_immich, module.app_immich_ml ]

    container_port = 2283
    dns_config = {
        cluster_fqdn = var.cluster_fqdn
        host_ip = local.primary_ingress_ip
        subdomain_name = "immich"
    }
    environment = {
        DB_DATABASE_NAME = "immich"
        DB_HOSTNAME = local.postgres_pgvecto_rs_service_hostname
        DB_PASSWORD = random_password.immich_database_user.result
        DB_PORT = "5432"
        DB_USERNAME = "immich"
        IMMICH_CONFIG_FILE = "/usr/src/app/immich.json"
        IMMICH_PORT = "2283"
        REDIS_DBINDEX = local.redis_db_reservations.immich
        REDIS_HOSTNAME = local.redis_service_hostname
        REDIS_PASSWORD = var.db_redis_root
        REDIS_PORT = "6379"
        TZ = "Europe/Helsinki"
    }
    files = {
        "/usr/src/app/immich.json" = file("${path.module}/config/immich/immich.json")
    }
    image = {
        tag = local.immich_tag
        uri = "ghcr.io/immich-app/immich-server"
    }
    ingress_upload_size = "5G"
    name = "immich"
    namespace = kubernetes_namespace.family.metadata[0].name
    replicas = 1
    service_port = 80
    tailscale = {
        hostname = "immich"
        host_ip = local.primary_ingress_ip
        tailnet = var.tailscale_tailnet
    }
    subdir_mounts = {
        "upload" = {
            container_path = "/usr/src/app/upload"
            storage = "photos"
            storage_request = "1500Gi"
        }
    }
}
