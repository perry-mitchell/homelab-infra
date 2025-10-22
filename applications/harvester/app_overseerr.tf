module "app_overseerr" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    overseerr = {
      environment = {
        PGID = "100"
        PUID = "99"
        TZ   = "Europe/Helsinki"
      }
      image = {
        tag = "latest"
        uri = "lscr.io/linuxserver/overseerr"
      }
      longhorn_mounts = {
        config = {
          container_path  = "/config"
          storage_request = "10Gi"
        }
      }
      ports = [
        {
          container = 5055
          service   = 80
          tailscale_hostname  = "overseerr"
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "overseerr"
  namespace              = kubernetes_namespace.entertainment.metadata.0.name
}
