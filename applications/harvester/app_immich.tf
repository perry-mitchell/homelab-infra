locals {
  immich_tag = "v2.2.0"
}

module "db_immich_postgres" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    "immich-postgres" = {
      environment = {
        PGDATA            = "/var/lib/postgresql/data"
        POSTGRES_PASSWORD = var.db_postgres_pgvecto_rs_root
        POSTGRES_USER     = "root"
        TZ                = "Europe/Helsinki"
      }
      image = local.images.immich_postgres
      longhorn_mounts = {
        data = {
          container_path  = "/var/lib/postgresql/data"
          storage_request = "20Gi"
        }
      }
      ports = [
        {
          container         = 5432
          internal_hostname = "immich-postgres"
          service = 5432
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "immich-postgres"
  namespace              = kubernetes_namespace.home_media.metadata.0.name
  replicas = local.deployments_enabled.datasource ? 1 : 0
}

resource "random_password" "immich_database_user" {
  length  = 32
  special = false
}

module "db_init_immich" {
  source = "../../modules-harvester/postgres-init"

  depends_on = [module.db_immich_postgres]

  create_database = "immich"
  create_user = {
    password = random_password.immich_database_user.result
    username = "immich"
  }
  db_host     = "immich-postgres"
  db_password = var.db_postgres_pgvecto_rs_root
  db_username = "root"
  extra_sql_lines = [
    "ALTER USER immich WITH SUPERUSER",
    "CREATE EXTENSION IF NOT EXISTS vectors",
    "CREATE EXTENSION IF NOT EXISTS earthdistance CASCADE"
  ]
  name      = "immich"
  namespace = kubernetes_namespace.home_media.metadata.0.name
}

module "app_immich_ml" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    "immich-ml" = {
      environment = {
        IMMICH_HOST = "0.0.0.0"
        IMMICH_PORT = "3003"
        TZ          = "Europe/Helsinki"
      }
      image = local.images.immich_ml
      longhorn_mounts = {
        "model-cache" = {
          container_path  = "/cache"
          storage_request = "50Gi"
        }
      }
      ports = [
        {
          container         = 3003
          internal_hostname = "immich-ml"
          service           = 3003
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "immich-ml"
  namespace              = kubernetes_namespace.home_media.metadata.0.name
  replicas = local.deployments_enabled.service ? 1 : 0
}

module "app_immich" {
  source = "../../modules-harvester/service"

  depends_on = [module.db_init_immich, module.app_immich_ml]

  cluster_name = var.cluster_name
  containers = {
    immich = {
      environment = {
        DB_DATABASE_NAME   = "immich"
        DB_HOSTNAME        = "immich-postgres"
        DB_PASSWORD        = random_password.immich_database_user.result
        DB_PORT            = "5432"
        DB_USERNAME        = "immich"
        IMMICH_CONFIG_FILE = "/usr/src/app/immich.json"
        IMMICH_PORT        = "2283"
        REDIS_DBINDEX      = local.redis_db_reservations.immich
        REDIS_HOSTNAME     = local.shared_redis_cluster_hostname
        REDIS_PASSWORD     = var.db_redis_root
        REDIS_PORT         = "6379"
        TZ                 = "Europe/Helsinki"
      }
      image = local.images.immich_server
      nfs_mounts = {
        upload = {
          create_subdir   = true
          container_path  = "/usr/src/app/upload"
          nfs_export      = var.nfs_storage.photos.export
          nfs_server      = var.nfs_storage.photos.host
          storage_request = "1500Gi"
        }
      }
      ports = [
        {
          container          = 2283
          service            = 80
          tailscale_hostname = "immich"
        }
      ]
      static_mounts = {
        "/usr/src/app/immich.json" = file("${path.module}/config/immich/immich.json")
      }
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "immich"
  namespace              = kubernetes_namespace.home_media.metadata.0.name
  replicas = local.deployments_enabled.service ? 1 : 0
}
