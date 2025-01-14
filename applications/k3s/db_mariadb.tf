module "db_mariadb" {
    source = "../../modules/service"

    depends_on = [ module.nfs_storage_subdir ]

    container_port = 3306
    # dns_config = {
    #     cluster_fqdn = var.cluster_fqdn
    #     host_ip = local.primary_ingress_ip
    #     subdomain_name = "mariadb"
    # }
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
    service_port = 3306
    subdir_mounts = {
        mysql = {
            container_path = "/var/lib/mysql"
            storage = "appdata"
            storage_request = "50Gi"
        }
    }
    # tailscale = {
    #   hostname = "mariadb"
    #   host_ip = local.primary_ingress_ip
    #   tailnet = var.tailscale_tailnet
    # }
}
