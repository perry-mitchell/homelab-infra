module "app_n8n" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    n8n = {
      fs_group = 1000
      image    = local.images.n8n
      longhorn_mounts = {
        data = {
          container_path  = "/home/node/.n8n"
          storage_request = "10Gi"
        }
      }
      ports = [
        {
          container          = 5678
          service            = 80
          tailscale_hostname = "n8n"
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "n8n"
  namespace              = kubernetes_namespace.programming.metadata.0.name
  replicas               = local.deployments_enabled.service ? 1 : 0
}
