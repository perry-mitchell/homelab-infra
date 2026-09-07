resource "random_password" "trek_encryption_key" {
  length  = 64
  special = false
}

module "app_trek" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    trek = {
      fs_group = 1000
      environment = {
        TZ             = "Europe/Helsinki"
        ENCRYPTION_KEY = random_password.trek_encryption_key.result
      }
      image = local.images.trek
      longhorn_mounts = {
        data = {
          container_path  = "/app/data"
          storage_request = "5Gi"
        }
        uploads = {
          container_path  = "/app/uploads"
          storage_request = "10Gi"
        }
      }
      ports = [
        {
          container = 3000
          service   = 80
          public_access = {
            hostname = "trek.${var.public_domain}"
          }
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "trek"
  namespace              = kubernetes_namespace.travel.metadata.0.name
  replicas               = local.deployments_enabled.service ? 1 : 0
}
