module "app_gitsave" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    gitsave = {
      environment = {
        DISABLE_AUTH = "false"
        ENCRYPTION_SECRET = var.gitsave.encryption_secret
        JWT_SECRET   = var.gitsave.jwt
      }
      image = {
        tag = "latest"
        uri = "timwitzdam/gitsave"
      }
      longhorn_mounts = {
        data = {
          container_path  = "/app/data"
          storage_request = "1Gi"
        }
      }
      nfs_mounts = {
        backups = {
          create_subdir   = true
          container_path  = "/app/backups"
          nfs_export      = var.nfs_storage.backup.export
          nfs_server      = var.nfs_storage.backup.host
          storage_request = "100Gi"
        }
      }
      ports = [
        {
          container = 3000
          hostname  = "gitsave"
          service   = 80
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "gitsave"
  namespace              = kubernetes_namespace.backup.metadata.0.name
  replicas = 1
}
