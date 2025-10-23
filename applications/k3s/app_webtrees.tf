locals {
  webtrees_url = "http://webtrees.${var.tailscale_tailnet}"
}

resource "random_password" "webtrees_database_user" {
  length  = 32
  special = false
}

module "db_init_webtrees" {
  source = "../../modules/mysql-init"

  depends_on = [module.db_mariadb]

  create_database = "webtrees"
  create_user = {
    password = random_password.webtrees_database_user.result
    username = "webtrees"
  }
  db_host     = local.mariadb_service_hostname
  db_password = var.db_mariadb_root
  db_username = "root"
  grant_users = {
    "webtrees" = "webtrees"
  }
  name = "webtrees"
}

# module "app_webtrees" {
#   source = "../../modules/service2"

#   depends_on = [module.db_init_webtrees, module.nfs_storage_export]

#   container_port = 80
#   dns_config = {
#     cluster_fqdn   = var.cluster_fqdn
#     host_ip        = local.primary_ingress_ip
#     subdomain_name = "webtrees"
#   }
#   environment = {
#     BASE_URL    = local.webtrees_url
#     DB_HOST     = local.mariadb_service_hostname
#     DB_NAME     = "webtrees"
#     DB_PASS     = random_password.webtrees_database_user.result
#     DB_PORT     = 3306
#     DB_USER     = "webtrees"
#     PRETTY_URLS = "yes"
#     WT_EMAIL    = var.webtrees_admin.email
#     WT_NAME     = var.webtrees_admin.name
#     WT_PASS     = var.webtrees_admin.password
#     WT_USER     = var.webtrees_admin.username
#   }
#   image = {
#     tag = "latest"
#     uri = "nathanvaughn/webtrees"
#   }
#   name      = "webtrees"
#   namespace = kubernetes_namespace.family.metadata[0].name
#   nfs_mounts = {
#     data = {
#       create_subdir   = true
#       container_path  = "/var/www/webtrees/data"
#       nfs_export      = var.nfs_storage.appdata.export
#       nfs_server      = var.nfs_storage.appdata.host
#       storage_request = "10Gi"
#     }
#   }
#   replicas     = 0
#   service_port = 80
#   tailscale = {
#     hostname = "webtrees-old"
#     host_ip  = local.primary_ingress_ip
#     tailnet  = var.tailscale_tailnet
#   }
# }
