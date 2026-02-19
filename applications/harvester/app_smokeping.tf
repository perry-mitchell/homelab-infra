module "app_smokeping" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    smokeping = {
      image = local.images.smokeping
      longhorn_mounts = {
        data = {
          container_path  = "/data"
          storage_request = "5Gi"
        }
      }
      ports = [
        {
          container = 80
          service   = 80
          tailscale_hostname  = "smokeping"
        }
      ]
      static_mounts = {
        "/config/Targets" = file("${path.module}/config/smokeping/Targets")
      }
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "smokeping"
  namespace              = kubernetes_namespace.monitoring.metadata.0.name
  replicas = local.deployments_enabled.service ? 1 : 0
}
