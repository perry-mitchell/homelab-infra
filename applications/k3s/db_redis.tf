module "db_redis" {
    source = "../../modules/service"

    depends_on = [ module.nfs_storage ]

    container_port = 6379
    # dns_config = {
    #     cluster_fqdn = var.cluster_fqdn
    #     host_ip = local.primary_ingress_ip
    #     subdomain_name = "redis"
    # }
    environment = {
        ALLOW_EMPTY_PASSWORD = "no"
        REDIS_PASSWORD = var.db_redis_root
    }
    image = {
        tag = "latest"
        uri = "bitnami/redis"
    }
    mounts = {
        data = {
            container_path = "/bitnami/redis/data"
            storage = "appdata"
            storage_request = "10Gi"
        }
    }
    name = local.redis_service_name
    namespace = kubernetes_namespace.datasources.metadata[0].name
    service_port = 6379
    # tailscale = {
    #   hostname = "redis"
    #   tailnet = var.tailscale_tailnet
    # }
}
