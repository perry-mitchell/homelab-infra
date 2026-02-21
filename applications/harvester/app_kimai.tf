module "db_kimai_mariadb" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    "kimai-mariadb" = {
      environment = {
        MARIADB_ROOT_PASSWORD = var.db_mariadb_root
        TZ                    = "Europe/Helsinki"
      }
      image = local.images.kimai_db
      longhorn_mounts = {
        mysql = {
          container_path  = "/var/lib/mysql"
          storage_request = "20Gi"
        }
      }
      ports = [
        {
          container         = 3306
          internal_hostname = "kimai-mariadb"
          service           = 3306
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "kimai-mariadb"
  namespace              = kubernetes_namespace.freelancing.metadata.0.name
  replicas = local.deployments_enabled.datasource ? 1 : 0
}

resource "random_password" "kimai_database_user" {
  length  = 32
  special = false
}

module "db_init_kimai" {
  source = "../../modules-harvester/mysql-init"

  depends_on = [module.db_kimai_mariadb]

  create_database = "kimai"
  create_user = {
    password = random_password.kimai_database_user.result
    username = "kimai"
  }
  db_host     = "kimai-mariadb"
  db_password = var.db_mariadb_root
  db_username = "root"
  grant_users = {
    "kimai" = "kimai"
  }
  name      = "kimai"
  namespace = kubernetes_namespace.freelancing.metadata.0.name
}

module "app_kimai" {
  source = "../../modules-harvester/service"

  depends_on = [module.db_init_kimai]

  cluster_name = var.cluster_name
  containers = {
    kimai = {
      environment = {
        ADMINMAIL       = var.kimai_admin.email
        ADMINPASS       = var.kimai_admin.password
        DATABASE_URL    = "mysql://kimai:${random_password.kimai_database_user.result}@${"kimai-mariadb"}:3306/kimai?charset=utf8mb4"
        TRUSTED_HOSTS   = "localhost|kimai.atlas-dragon.ts.net"
        TRUSTED_PROXIES = "10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
        TZ              = "Europe/Helsinki"
      }
      image = local.images.kimai
      longhorn_mounts = {
        data = {
          container_path  = "/opt/kimai/var/data"
          storage_request = "20Gi"
        }
      }
      ports = [
        {
          container          = 8001
          service            = 80
          tailscale_hostname = "kimai"
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "kimai"
  namespace              = kubernetes_namespace.freelancing.metadata.0.name
  replicas = local.deployments_enabled.service ? 1 : 0
}
