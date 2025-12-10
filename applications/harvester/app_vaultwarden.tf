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
          service   = 80
          tailscale_hostname  = "vaultwarden"
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "vaultwarden"
  namespace              = kubernetes_namespace.authentication.metadata.0.name
  replicas               = local.deployments_enabled.service ? 1 : 0
}
