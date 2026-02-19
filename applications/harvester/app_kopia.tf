module "app_kopia" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    kopia = {
      environment = {
        KOPIA_PERSIST_CREDENTIALS_ON_CONNECT = "true"
        PASSWORD                             = var.kopia_admin.password
        # PGID                                 = "0"
        # PUID                                 = "0"
        TZ                                   = "Europe/Helsinki"
        USERNAME                             = var.kopia_admin.username
      }
      image = local.images.kopia
      longhorn_mounts = {
        cache = {
          container_path = "/cache"
          storage_request = "50Gi"
        }
        config = {
          container_path  = "/config"
          storage_request = "10Gi"
        }
        repository = {
          container_path = "/local"
          storage_request = "50Gi"
        }
        temp = {
          container_path = "/tmp"
          storage_request = "10Gi"
        }
      }
      nfs_mounts = {
        photos = {
          create_subdir   = false
          container_path  = "/source/photos"
          nfs_export      = var.nfs_storage.photos.export
          nfs_server      = var.nfs_storage.photos.host
          read_only       = true
          storage_request = "1Ti"
        }
      }
      ports = [
        {
          container = 51515
          service   = 80
          tailscale_hostname  = "kopia"
        }
      ]
      # run_as = {
      #   user  = 0
      #   group = 0
      # }
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "kopia"
  namespace              = kubernetes_namespace.backup.metadata.0.name
  replicas = local.deployments_enabled.service ? 1 : 0
}

