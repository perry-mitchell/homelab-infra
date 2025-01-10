module "db_postgres" {
    source = "../../modules/service"

    depends_on = [ module.nfs_storage_subdir ]

    container_port = 5432
    # dns_config = {
    #     cluster_fqdn = var.cluster_fqdn
    #     host_ip = local.primary_ingress_ip
    #     subdomain_name = "postgres"
    # }
    environment = {
        PGDATA = "/var/lib/postgresql/dbdata"
        POSTGRES_PASSWORD = var.db_postgres_root
        POSTGRES_USER = "root"
        TZ = "Europe/Helsinki"
    }
    image = {
        tag = "13"
        uri = "postgres"
    }
    name = local.postgres_service_name
    namespace = kubernetes_namespace.datasources.metadata[0].name
    service_port = 5432
    subdir_mounts = {
        data = {
            container_path = "/var/lib/postgres/dbdata"
            storage = "appdata"
            storage_request = "50Gi"
        }
    }
}

module "db_postgres_pgvecto_rs" {
    source = "../../modules/service"

    depends_on = [ module.nfs_storage_subdir ]

    container_port = 5432
    # dns_config = {
    #     cluster_fqdn = var.cluster_fqdn
    #     host_ip = local.primary_ingress_ip
    #     subdomain_name = "postgres-pgvecto-rs"
    # }
    environment = {
        PGDATA = "/var/lib/postgresql/dbdata"
        POSTGRES_PASSWORD = var.db_postgres_pgvecto_rs_root
        POSTGRES_USER = "root"
        TZ = "Europe/Helsinki"
    }
    image = {
        tag = "pg14-v0.2.0"
        uri = "tensorchord/pgvecto-rs"
    }
    name = local.postgres_pgvecto_rs_service_name
    namespace = kubernetes_namespace.datasources.metadata[0].name
    service_port = 5432
    subdir_mounts = {
        data = {
            container_path = "/var/lib/postgresql/dbdata"
            storage = "appdata"
            storage_request = "50Gi"
        }
    }
}

module "db_postgres_postgis" {
    source = "../../modules/service"

    depends_on = [ module.nfs_storage_subdir ]

    container_port = 5432
    # dns_config = {
    #     cluster_fqdn = var.cluster_fqdn
    #     host_ip = local.primary_ingress_ip
    #     subdomain_name = "postgres"
    # }
    environment = {
        PGDATA = "/var/lib/postgresql/dbdata"
        POSTGRES_PASSWORD = var.db_postgres_postgis_root
        POSTGRES_USER = "root"
        TZ = "Europe/Helsinki"
    }
    image = {
        tag = "17-3.5"
        uri = "postgis/postgis"
    }
    name = local.postgres_postgis_service_name
    namespace = kubernetes_namespace.datasources.metadata[0].name
    service_port = 5432
    subdir_mounts = {
        data = {
            container_path = "/var/lib/postgresql/dbdata"
            storage = "appdata"
            storage_request = "25Gi"
        }
    }
}
