locals {
  mealie_host = "mealie.${var.tailscale_tailnet}"
  mealie_url = "https://${local.mealie_host}"
}

module "db_mealie_postgres" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    "mealie-postgres" = {
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
          internal_hostname = "mealie-postgres"
          service = 5432
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "mealie-postgres"
  namespace              = kubernetes_namespace.food.metadata.0.name
  replicas = local.deployments_enabled.datasource ? 1 : 0
}

resource "random_password" "mealie_database_user" {
  length  = 32
  special = false
}

module "db_init_mealie" {
  source = "../../modules-harvester/postgres-init"

  depends_on = [module.db_mealie_postgres]

  create_database = "mealie"
  create_user = {
    password = random_password.mealie_database_user.result
    username = "mealie"
  }
  db_host     = "mealie-postgres"
  db_password = var.db_postgres_root
  db_username = "root"
  extra_sql_lines = [
    "ALTER USER mealie WITH SUPERUSER"
  ]
  name      = "mealie"
  namespace = kubernetes_namespace.food.metadata.0.name
}

module "app_mealie" {
  source = "../../modules-harvester/service"

  depends_on = [ module.db_init_mealie ]

  cluster_name = var.cluster_name
  containers = {
    mealie = {
      environment = {
        ALLOW_SIGNUP = "true"
        BASE_URL = local.mealie_url
        LOG_LEVEL = "INFO"
        DB_ENGINE ="postgres"
        POSTGRES_USER = "mealie"
        POSTGRES_PASSWORD = random_password.mealie_database_user.result
        POSTGRES_SERVER = "mealie-postgres"
        POSTGRES_PORT = "5432"
        POSTGRES_DB ="mealie"
      }
      image = {
        tag = "latest"
        uri = "hkotel/mealie"
      }
      longhorn_mounts = {
        data = {
          container_path  = "/app/data"
          storage_request = "15Gi"
        }
      }
      ports = [
        {
          container = 9000
          service   = 80
          tailscale_hostname  = "mealie"
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "mealie"
  namespace              = kubernetes_namespace.food.metadata.0.name
  replicas = local.deployments_enabled.service ? 1 : 0
}
