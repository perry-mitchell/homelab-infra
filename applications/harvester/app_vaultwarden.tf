module "app_vaultwarden" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    vaultwarden = {
      image = {
        tag = "latest"
        uri = "vaultwarden/server"
      }
      longhorn_mounts = {
        data = {
          container_path  = "/data"
          storage_request = "50Gi"
        }
      }
      ports = [
        {
          container = 80
          hostname  = "vaultwarden"
          service   = 80
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "vaultwarden"
  namespace              = kubernetes_namespace.authentication.metadata.0.name
  replicas               = 1
}
