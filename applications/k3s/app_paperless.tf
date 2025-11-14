resource "random_password" "paperless_database_user" {
  length  = 32
  special = false
}

module "db_init_paperless" {
  source = "../../modules/mysql-init"

  depends_on = [module.db_mariadb]

  create_database = "paperless"
  create_user = {
    password = random_password.paperless_database_user.result
    username = "paperless"
  }
  db_host     = local.mariadb_service_hostname
  db_password = var.db_mariadb_root
  db_username = "root"
  grant_users = {
    "paperless" = "paperless"
  }
  name = "paperless"
}

# module "app_paperless" {
#   source = "../../modules/service2"

#   depends_on = [module.db_init_paperless, module.nfs_storage_export, module.db_redis]

#   container_port = 8000
#   dns_config = {
#     cluster_fqdn   = var.cluster_fqdn
#     host_ip        = local.primary_ingress_ip
#     subdomain_name = "paperless"
#   }
#   environment = {
#     PAPERLESS_ADMIN_MAIL       = var.paperless_auth.admin_mail
#     PAPERLESS_ADMIN_PASSWORD   = var.paperless_auth.admin_password
#     PAPERLESS_ADMIN_USER       = var.paperless_auth.admin_user
#     PAPERLESS_CONSUMPTION_DIR  = "/data/consume"
#     PAPERLESS_DATA_DIR         = "/config"
#     PAPERLESS_DBENGINE         = "mariadb"
#     PAPERLESS_DBPASS           = random_password.paperless_database_user.result
#     PAPERLESS_DBHOST           = local.mariadb_service_hostname
#     PAPERLESS_DBUSER           = "paperless"
#     PAPERLESS_MEDIA_ROOT       = "/data/media"
#     PAPERLESS_PORT             = "8000"
#     PAPERLESS_REDIS            = "redis://:${var.db_redis_root}@${local.redis_service_hostname}:6379/${local.redis_db_reservations.paperless}"
#     PAPERLESS_TIME_ZONE        = "Europe/Helsinki"
#     PAPERLESS_CONSUMER_POLLING = "60"
#     USERMAP_UID                = "99"
#     USERMAP_GID                = "100"
#   }
#   image = {
#     tag = "latest"
#     uri = "paperlessngx/paperless-ngx"
#   }
#   longhorn_mounts = {
#     config = {
#       container_path  = "/config"
#       storage_request = "10Gi"
#     }
#   }
#   name      = "paperless"
#   namespace = kubernetes_namespace.family.metadata[0].name
#   nfs_mounts = {
#     data = {
#       create_subdir   = true
#       container_path  = "/data"
#       nfs_export      = var.nfs_storage.appdata.export
#       nfs_server      = var.nfs_storage.appdata.host
#       storage_request = "100Gi"
#     }
#   }
#   replicas     = 0
#   service_port = 80
#   tailscale = {
#     hostname = "paperless2"
#     host_ip  = local.primary_ingress_ip
#     tailnet  = var.tailscale_tailnet
#   }
# }
