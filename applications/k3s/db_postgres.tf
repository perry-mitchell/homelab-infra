module "db_postgres" {
    source = "../../modules/service"

    depends_on = [ module.nfs_storage ]

    container_port = 5432
    # dns_config = {
    #     cluster_fqdn = var.cluster_fqdn
    #     host_ip = local.primary_ingress_ip
    #     subdomain_name = "postgres"
    # }
    environment = {
        POSTGRES_PASSWORD = var.db_postgres_root
        POSTGRES_USER = "root"
        TZ = "Europe/Helsinki"
    }
    image = {
        tag = "13"
        uri = "postgres"
    }
    mounts = {
        data = {
            container_path = "/var/lib/postgresql/data"
            storage = "appdata"
            storage_request = "50Gi"
        }
    }
    name = local.postgres_service_name
    namespace = kubernetes_namespace.datasources.metadata[0].name
    service_port = 5432
    tailscale = {
      hostname = "postgres"
      host_ip = local.primary_ingress_ip
      tailnet = var.tailscale_tailnet
    }
}

module "db_postgres_pgvecto_rs" {
    source = "../../modules/service"

    depends_on = [ module.nfs_storage ]

    container_port = 5432
    dns_config = {
        cluster_fqdn = var.cluster_fqdn
        host_ip = local.primary_ingress_ip
        subdomain_name = "postgres-pgvecto-rs"
    }
    environment = {
        POSTGRES_PASSWORD = var.db_postgres_pgvecto_rs_root
        POSTGRES_USER = "root"
        TZ = "Europe/Helsinki"
    }
    image = {
        tag = "pg14-v0.2.0"
        uri = "tensorchord/pgvecto-rs"
    }
    mounts = {
        data = {
            container_path = "/var/lib/postgresql/data"
            storage = "appdata"
            storage_request = "50Gi"
        }
    }
    name = local.postgres_pgvecto_rs_service_name
    namespace = kubernetes_namespace.datasources.metadata[0].name
    service_port = 5432
    tailscale = {
      hostname = "postgres-pgvecto-rs"
      host_ip = local.primary_ingress_ip
      tailnet = var.tailscale_tailnet
    }
}
