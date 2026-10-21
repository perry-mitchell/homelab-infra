resource "random_password" "authentik_database_user" {
  length  = 32
  special = false
}

module "db_authentik_postgres" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    "authentik-postgres" = {
      environment = {
        PGDATA            = "/var/lib/postgresql/data/pgdata"
        POSTGRES_PASSWORD = var.db_postgres_root
        POSTGRES_USER     = "root"
        TZ                = "Europe/Helsinki"
      }
      image = local.images.postgres
      longhorn_mounts = {
        data = {
          container_path  = "/var/lib/postgresql/data"
          storage_request = "10Gi"
        }
      }
      ports = [
        {
          container         = 5432
          internal_hostname = "authentik-postgres"
          service           = 5432
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "authentik-postgres"
  namespace              = kubernetes_namespace.authentication.metadata.0.name
  replicas               = local.deployments_enabled.datasource ? 1 : 0
}

module "db_init_authentik" {
  source = "../../modules-harvester/postgres-init"

  depends_on = [module.db_authentik_postgres]

  create_database = "authentik"
  create_user = {
    password = random_password.authentik_database_user.result
    username = "authentik"
  }
  db_host     = "authentik-postgres"
  db_password = var.db_postgres_root
  db_username = "root"
  name        = "authentik"
  namespace   = kubernetes_namespace.authentication.metadata.0.name
}

locals {
  authentik_host = "auth.${var.public_domain}"

  authentik_environment = {
    AUTHENTIK_BOOTSTRAP_EMAIL           = var.letsencrypt_email
    AUTHENTIK_BOOTSTRAP_PASSWORD        = var.authentik.bootstrap_password
    AUTHENTIK_POSTGRESQL__HOST          = "authentik-postgres"
    AUTHENTIK_POSTGRESQL__NAME          = "authentik"
    AUTHENTIK_POSTGRESQL__USER          = "authentik"
    AUTHENTIK_POSTGRESQL__PASSWORD      = random_password.authentik_database_user.result
    AUTHENTIK_REDIS__HOST               = local.shared_redis_cluster_hostname
    AUTHENTIK_REDIS__PASSWORD           = var.db_redis_root
    AUTHENTIK_REDIS__CACHE_DB           = tostring(local.redis_db_reservations.authentik_cache)
    AUTHENTIK_REDIS__TASK_DB            = tostring(local.redis_db_reservations.authentik_task)
    AUTHENTIK_REDIS__WS_DB              = tostring(local.redis_db_reservations.authentik_ws)
    AUTHENTIK_SECRET_KEY                = var.authentik.secret_key
    AUTHENTIK_WEB__CSRF_TRUSTED_ORIGINS = "https://${local.authentik_host}"
  }
}

module "app_authentik" {
  source = "../../modules-harvester/service"

  depends_on = [module.db_init_authentik]

  cluster_name = var.cluster_name
  containers = {
    "authentik-server" = {
      command     = ["server"]
      environment = local.authentik_environment
      image       = local.images.authentik
      ports = [
        {
          container = 9000
          service   = 80
          public_access = {
            hostname = local.authentik_host
          }
        }
      ]
    }
    "authentik-worker" = {
      command     = ["worker"]
      environment = local.authentik_environment
      image       = local.images.authentik
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "authentik"
  namespace              = kubernetes_namespace.authentication.metadata.0.name
  replicas               = local.deployments_enabled.service ? 1 : 0
}
