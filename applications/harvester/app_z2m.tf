module "app_z2m" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    z2m = {
      environment = {
        TZ = "Europe/Helsinki"
      }
      image = local.images.z2m
      longhorn_mounts = {
        data = {
          container_path  = "/app/data"
          storage_request = "15Gi"
        }
      }
      ports = [
        {
          container          = 8080
          service            = 80
          tailscale_hostname = "z2m"
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "z2m"
  namespace              = kubernetes_namespace.smart_home.metadata.0.name
  replicas               = local.deployments_enabled.service ? 1 : 0
}
