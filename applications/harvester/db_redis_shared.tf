module "db_redis_shared" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    "redis" = {
      environment = {
        ALLOW_EMPTY_PASSWORD = "no"
        REDIS_PASSWORD       = var.db_redis_root
      }
      fs_group = 1001
      image = {
        tag = "latest"
        uri = "bitnami/redis"
      }
      longhorn_mounts = {
        data = {
          container_path  = "/bitnami/redis/data"
          storage_request = "10Gi"
        }
      }
      ports = [
        {
          container         = 6379
          internal_hostname = "redis"
          service = 6379
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "redis"
  namespace              = kubernetes_namespace.shared_data.metadata.0.name
}
