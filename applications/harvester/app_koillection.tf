module "db_koillection_postgres" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    "koillection-postgres" = {
      environment = {
        PGDATA            = "/var/lib/postgresql/data/pgdata"
        POSTGRES_PASSWORD = var.db_postgres_root
        POSTGRES_USER     = "root"
        TZ                = "Europe/Helsinki"
      }
      image = {
        tag = "16"
        uri = "postgres"
      }
      longhorn_mounts = {
        data = {
          container_path  = "/var/lib/postgresql/data"
          storage_request = "20Gi"
        }
      }
      ports = [
        {
          container         = 5432
          internal_hostname = "koillection-postgres"
          service = 5432
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "koillection-postgres"
  namespace              = kubernetes_namespace.collecting.metadata.0.name
  replicas = local.deployments_enabled.datasource ? 1 : 0
}

resource "random_password" "koillection_database_user" {
  length  = 32
  special = false
}

module "db_init_koillection" {
  source = "../../modules-harvester/postgres-init"

  depends_on = [module.db_koillection_postgres]

  create_database = "koillection"
  create_user = {
    password = random_password.koillection_database_user.result
    username = "koillection"
  }
  db_host     = "koillection-postgres"
  db_password = var.db_postgres_root
  db_username = "root"
  extra_sql_lines = [
    "ALTER USER koillection WITH SUPERUSER"
  ]
  name      = "koillection"
  namespace = kubernetes_namespace.collecting.metadata.0.name
}

resource "random_password" "koillection_app_secret" {
  length  = 32
  special = false
}

module "app_koillection" {
  source = "../../modules-harvester/service"

  depends_on = [module.db_init_koillection]

  cluster_name = var.cluster_name
  containers = {
    koillection = {
      environment = {
        APP_DEBUG           = 0
        APP_ENV             = "prod"
        APP_SECRET          = random_password.koillection_app_secret.result
        HTTPS_ENABLED       = 1
        JWT_PASSPHRASE      = random_password.koillection_app_secret.result
        UPLOAD_MAX_FILESIZE = "20M"
        PHP_MEMORY_LIMIT    = "512M"
        PHP_TZ              = "Europe/Helsinki"
        DB_DRIVER           = "pdo_pgsql"
        DB_NAME             = "koillection"
        DB_HOST             = "koillection-postgres"
        DB_PORT             = 5432
        DB_USER             = "koillection"
        DB_PASSWORD         = random_password.koillection_database_user.result
        DB_VERSION          = 16
      }
      image = {
        tag = "1.7.0"
        uri = "koillection/koillection"
      }
      longhorn_mounts = {
        uploads = {
          container_path  = "/uploads"
          storage_request = "100Gi"
        }
      }
      ports = [
        {
          container          = 80
          service            = 80
          tailscale_hostname = "collect"
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "koillection"
  namespace              = kubernetes_namespace.collecting.metadata.0.name
  replicas = local.deployments_enabled.service ? 1 : 0
}
