resource "random_password" "adventurelog_database_user" {
  length  = 32
  special = false
}

resource "random_password" "adventurelog_secret_key" {
  length  = 32
  special = false
}

locals {
  adventurelog_host         = "adventurelog.${var.tailscale_tailnet}"
  adventurelog_url          = "https://${local.adventurelog_host}"
  adventurelog_backend_host = "adventurelog-backend.${var.tailscale_tailnet}"
  adventurelog_backend_url  = "https://${local.adventurelog_backend_host}"
}

locals {
  adventurelog_env = {
    # Front-end
    PUBLIC_SERVER_URL = "http://localhost:8000"
    # Database
    PGDATA = "/var/lib/postgresql/data/pgdata"
    PGHOST = "adventurelog-postgis"
    POSTGRES_DB = "adventurelog"
    POSTGRES_USER = "adventurelog"
    POSTGRES_PASSWORD = random_password.adventurelog_database_user.result
    # Backend
    CSRF_TRUSTED_ORIGINS = "http://localhost:3000,http://localhost:8000,${local.adventurelog_url},${local.adventurelog_backend_url}"
    DJANGO_ADMIN_EMAIL = var.adventurelog_django_admin.email
    DJANGO_ADMIN_PASSWORD = var.adventurelog_django_admin.password
    DJANGO_ADMIN_USERNAME = var.adventurelog_django_admin.username
    FRONTEND_URL = local.adventurelog_url
    PUBLIC_URL = local.adventurelog_backend_url
    SECRET_KEY = random_password.adventurelog_secret_key.result
  }
}

module "db_adventurelog_postgis" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    "adventurelog-postgis" = {
      environment = local.adventurelog_env
      image = local.images.adventurelog_postgis
      longhorn_mounts = {
        postgres = {
          container_path  = "/var/lib/postgresql/data"
          storage_request = "25Gi"
        }
      }
      ports = [
        {
          container         = 5432
          internal_hostname = "adventurelog-postgis"
          service           = 5432
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "adventurelog-postgis"
  namespace              = kubernetes_namespace.travel.metadata.0.name
  replicas = local.deployments_enabled.datasource ? 1 : 0
}

module "app_adventurelog" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    "adventurelog-backend" = {
      environment = local.adventurelog_env
      image = local.images.adventurelog_backend
      longhorn_mounts = {
        media = {
          container_path = "/code/media"
          storage_request = "75Gi"
        }
      }
      ports = [
        {
          container         = 80
          service           = 80
          tailscale_hostname = "adventurelog-backend"
        }
      ]
    }
    "adventurelog-frontend" = {
      environment = local.adventurelog_env
      image = local.images.adventurelog_frontend
      ports = [
        {
          container = 3000
          service = 80
          tailscale_hostname = "adventurelog"
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "adventurelog"
  namespace              = kubernetes_namespace.travel.metadata.0.name
  replicas               = local.deployments_enabled.service ? 1 : 0
}
