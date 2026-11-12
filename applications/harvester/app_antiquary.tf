module "db_antiquary_postgres" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    "antiquary-postgres" = {
      environment = {
        PGDATA            = "/var/lib/postgresql/data/pgdata"
        POSTGRES_PASSWORD = var.db_postgres_root
        POSTGRES_USER     = "root"
        TZ                = "Europe/Helsinki"
      }
      image = local.images.antiquary_postgres
      longhorn_mounts = {
        data = {
          container_path  = "/var/lib/postgresql/data"
          storage_request = "20Gi"
        }
      }
      ports = [
        {
          container         = 5432
          internal_hostname = "antiquary-postgres"
          service           = 5432
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "antiquary-postgres"
  namespace              = kubernetes_namespace.collecting.metadata.0.name
  replicas               = local.deployments_enabled.datasource ? 1 : 0
}

resource "random_password" "antiquary_database_user" {
  length  = 32
  special = false
}

module "db_init_antiquary" {
  source = "../../modules-harvester/postgres-init"

  depends_on = [module.db_antiquary_postgres]

  create_database = "antiquary"
  create_user = {
    password = random_password.antiquary_database_user.result
    username = "antiquary"
  }
  db_host     = "antiquary-postgres"
  db_password = var.db_postgres_root
  db_username = "root"
  name        = "antiquary"
  namespace   = kubernetes_namespace.collecting.metadata.0.name
}

module "app_antiquary" {
  source = "../../modules-harvester/service"

  depends_on = [module.db_init_antiquary]

  cluster_name = var.cluster_name
  containers = {
    antiquary = {
      environment = {
        DATABASE_URL = "postgres://antiquary:${random_password.antiquary_database_user.result}@antiquary-postgres:5432/antiquary"
        UPLOAD_DIR   = "/data/uploads"
        TZ           = "Europe/Helsinki"
      }
      image = local.images.antiquary
      longhorn_mounts = {
        uploads = {
          container_path  = "/data/uploads"
          storage_request = "20Gi"
        }
      }
      ports = [
        {
          container          = 3000
          service            = 80
          tailscale_hostname = "antiquary"
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "antiquary"
  namespace              = kubernetes_namespace.collecting.metadata.0.name
  replicas               = local.deployments_enabled.service ? 1 : 0
}
