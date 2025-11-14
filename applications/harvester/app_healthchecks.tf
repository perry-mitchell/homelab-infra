locals {
  healthchecks_host = "health.${var.tailscale_tailnet}"
  healthchecks_url  = "https://${local.healthchecks_host}"
}

module "db_healthchecks_mariadb" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    "healthchecks-mariadb" = {
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
          internal_hostname = "healthchecks-mariadb"
          service           = 3306
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "healthchecks-mariadb"
  namespace              = kubernetes_namespace.monitoring.metadata.0.name
}

resource "random_password" "healthchecks_database_user" {
  length  = 32
  special = false
}

module "db_init_healthchecks" {
  source = "../../modules-harvester/mysql-init"

  depends_on = [module.db_healthchecks_mariadb]

  create_database = "healthchecks"
  create_user = {
    password = random_password.healthchecks_database_user.result
    username = "healthchecks"
  }
  db_host     = "healthchecks-mariadb"
  db_password = var.db_mariadb_root
  db_username = "root"
  grant_users = {
    "healthchecks" = "healthchecks"
  }
  name      = "healthchecks"
  namespace = kubernetes_namespace.monitoring.metadata.0.name
}

resource "random_password" "healthchecks_secret" {
  length  = 32
  special = false
}

module "app_healthchecks" {
  source = "../../modules-harvester/service"

  depends_on = [module.db_init_healthchecks]

  cluster_name = var.cluster_name
  containers = {
    healthchecks = {
      environment = {
        ALLOWED_HOSTS       = local.healthchecks_host
        DB                  = "mysql"
        DB_HOST             = "healthchecks-mariadb"
        DB_NAME             = "healthchecks"
        DB_PASSWORD         = random_password.healthchecks_database_user.result
        DB_PORT             = "3306"
        DB_USER             = "healthchecks"
        DEBUG               = "False"
        DEFAULT_FROM_EMAIL  = var.healthchecks_email.from
        EMAIL_HOST          = var.healthchecks_email.host
        EMAIL_HOST_PASSWORD = var.healthchecks_email.password
        EMAIL_HOST_USER     = var.healthchecks_email.user
        EMAIL_PORT          = var.healthchecks_email.port
        EMAIL_USE_TLS       = var.healthchecks_email.tls ? "True" : "False"
        SECRET_KEY          = random_password.healthchecks_secret.result
        SITE_ROOT           = local.healthchecks_url
      }
      image = {
        tag = "latest"
        uri = "healthchecks/healthchecks"
      }
      longhorn_mounts = {
        data = {
          container_path  = "/data"
          storage_request = "20Gi"
        }
      }
      ports = [
        {
          container          = 8000
          internal_hostname  = "health"
          service            = 80
          tailscale_hostname = "health"
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "healthchecks"
  namespace              = kubernetes_namespace.monitoring.metadata.0.name
}
