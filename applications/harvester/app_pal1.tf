resource "random_password" "pal1_admin" {
  length  = 32
  special = false
}

module "app_pal1" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    pal1 = {
      environment = merge(
        {
          ADMIN_PASSWORD         = random_password.pal1_admin.result
          BACKUP_CRON_EXPRESSION = "0 */1 * * *"
          BACKUP_ENABLED         = "true"
          COMMUNITY              = "true"
          DELETE_OLD_BACKUPS     = "true"
          OLD_BACKUP_DAYS        = "7"
          PLAYERS                = "32"
          PORT                   = "8211"
          QUERY_PORT             = "27015"
          SERVER_NAME            = var.pal1_server_name
          TZ                     = "Europe/Helsinki"
        },
        var.pal1_server_password != "" ? { SERVER_PASSWORD = var.pal1_server_password } : {}
      )
      fs_group = 1000
      image    = local.images.pal1
      longhorn_mounts = {
        game = {
          container_path  = "/palworld"
          storage_request = "30Gi"
        }
      }
      ports = [
        {
          container = 8211
          node_port = 32111
          protocol  = "UDP"
          service   = 8211
        },
        {
          container = 27015
          node_port = 32115
          protocol  = "UDP"
          service   = 27015
        },
      ]
      resources = {
        memory_limit   = "32Gi"
        memory_request = "16Gi"
      }
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "pal1"
  namespace              = kubernetes_namespace.gaming.metadata.0.name
  replicas               = local.deployments_enabled.service ? 1 : 0
}
