locals {
  webtrees_url = "https://webtrees.${var.tailscale_tailnet}"
}

module "db_webtrees_mariadb" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    "webtrees-mariadb" = {
      environment = {
        MARIADB_ROOT_PASSWORD = var.db_mariadb_root
        TZ                    = "Europe/Helsinki"
      }
      image = local.images.webtrees_db
      longhorn_mounts = {
        mysql = {
          container_path  = "/var/lib/mysql"
          storage_request = "10Gi"
        }
      }
      ports = [
        {
          container         = 3306
          internal_hostname = "webtrees-mariadb"
          service           = 3306
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "webtrees-mariadb"
  namespace              = kubernetes_namespace.family.metadata.0.name
  replicas = local.deployments_enabled.datasource ? 1 : 0
}

resource "random_password" "webtrees_database_user" {
  length  = 32
  special = false
}

module "db_init_webtrees" {
  source = "../../modules-harvester/mysql-init"

  depends_on = [module.db_webtrees_mariadb]

  create_database = "webtrees"
  create_user = {
    password = random_password.webtrees_database_user.result
    username = "webtrees"
  }
  db_host     = "webtrees-mariadb"
  db_password = var.db_mariadb_root
  db_username = "root"
  grant_users = {
    "webtrees" = "webtrees"
  }
  name      = "webtrees"
  namespace = kubernetes_namespace.family.metadata.0.name
}

module "app_webtrees" {
  source = "../../modules-harvester/service"

  depends_on = [module.db_init_webtrees]

  cluster_name = var.cluster_name
  containers = {
    webtrees = {
      environment = {
        BASE_URL    = local.webtrees_url
        DB_HOST     = "webtrees-mariadb"
        DB_NAME     = "webtrees"
        DB_PASS     = random_password.webtrees_database_user.result
        DB_PORT     = 3306
        DB_USER     = "webtrees"
        PRETTY_URLS = "yes"
        WT_EMAIL    = var.webtrees_admin.email
        WT_NAME     = var.webtrees_admin.name
        WT_PASS     = var.webtrees_admin.password
        WT_USER     = var.webtrees_admin.username
      }
      image = local.images.webtrees
      longhorn_mounts = {
        data = {
          container_path  = "/var/www/webtrees/data"
          storage_request = "10Gi"
        }
      }
      ports = [
        {
          container          = 80
          service            = 80
          tailscale_hostname = "webtrees"
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "webtrees"
  namespace              = kubernetes_namespace.family.metadata.0.name
  replicas = local.deployments_enabled.service ? 1 : 0
}
