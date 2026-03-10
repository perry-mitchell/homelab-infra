resource "kubernetes_namespace" "maintenant" {
  metadata {
    name = "maintenant"
  }
}

module "app_maintenant" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    maintenant = {
      environment = {
        MAINTENANT_ADDR = "0.0.0.0:8080"
        MAINTENANT_DB = "/data/maintenant.db"
        MAINTENANT_RUNTIME = "kubernetes"
      }
      image = local.images.maintenant
      longhorn_mounts = {
        data = {
          container_path  = "/data"
          storage_request = "50Gi"
        }
      }
      ports = [
        {
          container          = 8080
          service            = 80
          tailscale_hostname = "maintenant"
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "maintenant"
  namespace              = kubernetes_namespace.maintenant.metadata.0.name
  replicas               = local.deployments_enabled.service ? 1 : 0
}
