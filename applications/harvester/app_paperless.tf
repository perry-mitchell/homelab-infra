locals {
  paperless_url = "https://paperless.${var.tailscale_tailnet}"
}

module "db_paperless_mariadb" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    "paperless-mariadb" = {
      environment = {
        MARIADB_ROOT_PASSWORD = var.db_mariadb_root
        TZ                    = "Europe/Helsinki"
      }
      image = {
        tag = "12"
        uri = "mariadb"
      }
      longhorn_mounts = {
        mysql = {
          container_path  = "/var/lib/mysql"
          storage_request = "20Gi"
        }
      }
      ports = [
        {
          container         = 3306
          internal_hostname = "paperless-mariadb"
          service           = 3306
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "paperless-mariadb"
  namespace              = kubernetes_namespace.organisation.metadata.0.name
}

resource "random_password" "paperless_database_user" {
  length  = 32
  special = false
}

module "db_init_paperless" {
  source = "../../modules-harvester/mysql-init"

  depends_on = [module.db_paperless_mariadb]

  create_database = "paperless"
  create_user = {
    password = random_password.paperless_database_user.result
    username = "paperless"
  }
  db_host     = "paperless-mariadb"
  db_password = var.db_mariadb_root
  db_username = "root"
  grant_users = {
    "paperless" = "paperless"
  }
  name      = "paperless"
  namespace = kubernetes_namespace.organisation.metadata.0.name
}

module "app_paperless" {
  source = "../../modules-harvester/service"

  depends_on = [module.db_init_paperless]

  cluster_name = var.cluster_name
  containers = {
    paperless = {
      environment = {
        PAPERLESS_ADMIN_MAIL           = var.paperless_auth.admin_mail
        PAPERLESS_ADMIN_PASSWORD       = var.paperless_auth.admin_password
        PAPERLESS_ADMIN_USER           = var.paperless_auth.admin_user
        PAPERLESS_CONSUMPTION_DIR      = "/data/consume"
        PAPERLESS_CSRF_TRUSTED_ORIGINS = local.paperless_url
        PAPERLESS_DATA_DIR             = "/config"
        PAPERLESS_DBENGINE             = "mariadb"
        PAPERLESS_DBPASS               = random_password.paperless_database_user.result
        PAPERLESS_DBHOST               = "paperless-mariadb"
        PAPERLESS_DBUSER               = "paperless"
        PAPERLESS_MEDIA_ROOT           = "/data/media"
        PAPERLESS_PORT                 = "8000"
        PAPERLESS_REDIS                = "redis://:${var.db_redis_root}@${local.shared_redis_cluster_hostname}:6379/${local.redis_db_reservations.paperless}"
        PAPERLESS_TIME_ZONE            = "Europe/Helsinki"
        PAPERLESS_CONSUMER_POLLING     = "60"
        USERMAP_UID                    = "99"
        USERMAP_GID                    = "100"
      }
      image = {
        tag = "latest"
        uri = "paperlessngx/paperless-ngx"
      }
      longhorn_mounts = {
        config = {
          container_path  = "/config"
          storage_request = "10Gi"
        }
        data = {
          container_path  = "/data"
          storage_request = "50Gi"
        }
      }
      ports = [
        {
          container          = 8000
          service            = 80
          tailscale_hostname = "paperless"
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "paperless"
  namespace              = kubernetes_namespace.organisation.metadata.0.name
  replicas               = 1
}
