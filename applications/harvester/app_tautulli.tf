module "app_tautulli" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    tautulli = {
      environment = {
        PGID = "100"
        PUID = "99"
        TZ   = "Europe/Helsinki"
      }
      image = {
        tag = "latest"
        uri = "lscr.io/linuxserver/tautulli"
      }
      longhorn_mounts = {
        config = {
          container_path  = "/config"
          storage_request = "10Gi"
        }
      }
      ports = [
        {
          container = 8181
          hostname  = "tautulli"
          service   = 80
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "tautulli"
  namespace              = kubernetes_namespace.entertainment.metadata.0.name
}
