module "db_atuin_postgres" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    "atuin-postgres" = {
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
          internal_hostname = "atuin-postgres"
          service = 5432
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "atuin-postgres"
  namespace              = kubernetes_namespace.programming.metadata.0.name
  replicas = local.deployments_enabled.datasource ? 1 : 0
}

resource "random_password" "atuin_database_user" {
  length  = 32
  special = false
}

module "db_init_atuin" {
  source = "../../modules-harvester/postgres-init"

  depends_on = [module.db_atuin_postgres]

  create_database = "atuin"
  create_user = {
    password = random_password.atuin_database_user.result
    username = "atuin"
  }
  db_host     = "atuin-postgres"
  db_password = var.db_postgres_root
  db_username = "root"
  extra_sql_lines = [
    "ALTER USER atuin WITH SUPERUSER"
  ]
  name      = "atuin"
  namespace = kubernetes_namespace.programming.metadata.0.name
}

module "app_atuin" {
  source = "../../modules-harvester/service"

  depends_on = [ module.db_init_atuin ]

  cluster_name = var.cluster_name
  containers = {
    atuin = {
      args = ["server", "start"]
      environment = {
        ATUIN_HOST = "0.0.0.0"
        ATUIN_OPEN_REGISTRATION = "true"
        ATUIN_DB_URI = "postgres://${"atuin"}:${random_password.atuin_database_user.result}@atuin-postgres/${"atuin"}"
        RUST_LOG = "info,atuin_server=debug"
      }
      image = {
        tag = "18.10.0"
        uri = "ghcr.io/atuinsh/atuin"
      }
      ports = [
        {
          container = 8888
          service   = 80
          tailscale_hostname  = "atuin"
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "atuin"
  namespace              = kubernetes_namespace.programming.metadata.0.name
  replicas = local.deployments_enabled.service ? 1 : 0
}
