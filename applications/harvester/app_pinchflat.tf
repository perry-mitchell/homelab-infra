module "app_pinchflat" {
  source = "../../modules-harvester/service"
  cluster_name = var.cluster_name
  containers = {
    pinchflat = {
      image = local.images.pinchflat
      longhorn_mounts = {
        config = {
          container_path = "/config"
          storage_request = "1Gi"
        }
      }
      nfs_mounts = {
        media = {
          create_subdir   = true
          container_path  = "/downloads"
          nfs_export      = var.nfs_storage.entertainment.export
          nfs_server      = var.nfs_storage.entertainment.host
          storage_request = "1000Gi"
        }
      }
      ports = [
        {
          container = 8945
          service   = 80
          tailscale_hostname = "pinchflat"
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "pinchflat"
  namespace              = kubernetes_namespace.entertainment.metadata.0.name
  replicas               = local.deployments_enabled.service ? 1 : 0
}
