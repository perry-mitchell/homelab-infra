# locals {
#   seafile_host = "seafile.${var.tailscale_tailnet}"
# }

# module "db_seafile_mariadb" {
#   source = "../../modules-harvester/service"

#   cluster_name = var.cluster_name
#   containers = {
#     "seafile-mariadb" = {
#       environment = {
#         MARIADB_ROOT_PASSWORD = var.db_mariadb_root
#         TZ                    = "Europe/Helsinki"
#       }
#       image = {
#         tag = "12"
#         uri = "mariadb"
#       }
#       longhorn_mounts = {
#         mysql = {
#           container_path  = "/var/lib/mysql"
#           storage_request = "20Gi"
#         }
#       }
#       ports = [
#         {
#           container         = 3306
#           internal_hostname = "seafile-mariadb"
#           service           = 3306
#         }
#       ]
#     }
#   }
#   longhorn_storage_class = var.longhorn_storage_class
#   name                   = "seafile-mariadb"
#   namespace              = kubernetes_namespace.organisation.metadata.0.name
# }

# resource "random_password" "seafile_database_user" {
#   length  = 32
#   special = false
# }

# module "db_init_seafile" {
#   source = "../../modules-harvester/mysql-init"

#   depends_on = [module.db_seafile_mariadb]

#   create_database = "seafile"
#   create_user = {
#     password = random_password.seafile_database_user.result
#     username = "seafile"
#   }
#   db_host     = "seafile-mariadb"
#   db_password = var.db_mariadb_root
#   db_username = "root"
#   grant_users = {
#     "seafile" = "seafile"
#   }
#   name      = "seafile"
#   namespace = kubernetes_namespace.organisation.metadata.0.name
# }

# module "app_seafile_memcached" {
#   source = "../../modules-harvester/service"

#   cluster_name = var.cluster_name
#   containers = {
#     "seafile-memcached" = {
#       command = ["memcached", "-m", "256"]
#       image = {
#         tag = "1.6"
#         uri = "memcached"
#       }
#       ports = [
#         {
#           container         = 11211
#           internal_hostname = "memcached"
#           service           = 11211
#         }
#       ]
#     }
#   }
#   longhorn_storage_class = var.longhorn_storage_class
#   name                   = "seafile-memcached"
#   namespace              = kubernetes_namespace.organisation.metadata.0.name
# }

# module "app_seafile" {
#   source = "../../modules-harvester/service"

#   depends_on = [module.db_init_seafile, module.app_seafile_memcached]

#   cluster_name = var.cluster_name
#   containers = {
#     seafile = {
#       environment = {
#         SEAFILE_ADMIN_EMAIL              = var.seafile_admin.email
#         SEAFILE_ADMIN_PASSWORD           = var.seafile_admin.password
#         SEAFILE_SERVER_HOSTNAME          = local.seafile_host
#         SEAFILE_SERVER_PROTOCOL          = "https"
#         DB_HOST                          = "seafile-mariadb"
#         DB_PORT                          = 3306
#         INIT_SEAFILE_MYSQL_ROOT_PASSWORD = var.db_mariadb_root
#         SEAFILE_MYSQL_DB_PASSWORD        = random_password.seafile_database_user.result
#         TIME_ZONE                        = "Europe/Helsinki"
#       }
#       image = {
#         tag = "13.0-latest"
#         uri = "seafileltd/seafile-mc"
#       }
#       nfs_mounts = {
#         shared = {
#           create_subdir   = true
#           container_path  = "/shared"
#           nfs_export      = var.nfs_storage.appdata.export
#           nfs_server      = var.nfs_storage.appdata.host
#           storage_request = "750Gi"
#         }
#       }
#       ports = [
#         {
#           container          = 80
#           service            = 80
#           tailscale_hostname = "seafile"
#         }
#       ]
#     }
#   }
#   longhorn_storage_class = var.longhorn_storage_class
#   name                   = "seafile"
#   namespace              = kubernetes_namespace.organisation.metadata.0.name
# }
