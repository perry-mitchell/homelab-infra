module "db_gbrain_postgres" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    "gbrain-postgres" = {
      environment = {
        PGDATA            = "/var/lib/postgresql/data/pgdata"
        POSTGRES_PASSWORD = var.db_postgres_root
        POSTGRES_USER     = "root"
        TZ                = "Europe/Helsinki"
      }
      image = local.images.gbrain_postgres
      longhorn_mounts = {
        data = {
          container_path  = "/var/lib/postgresql/data"
          storage_request = "20Gi"
        }
      }
      ports = [
        {
          container         = 5432
          internal_hostname = "gbrain-postgres"
          service           = 5432
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "gbrain-postgres"
  namespace              = kubernetes_namespace.agents.metadata.0.name
  replicas               = local.deployments_enabled.datasource ? 1 : 0
}

resource "random_password" "gbrain_database_user" {
  length  = 32
  special = false
}

module "db_init_gbrain" {
  source = "../../modules-harvester/postgres-init"

  depends_on = [module.db_gbrain_postgres]

  create_database = "gbrain"
  create_user = {
    password = random_password.gbrain_database_user.result
    username = "gbrain"
  }
  db_host     = "gbrain-postgres"
  db_password = var.db_postgres_root
  db_username = "root"
  extra_sql_lines = [
    "ALTER USER gbrain WITH BYPASSRLS",
    "ALTER USER gbrain WITH SUPERUSER",
    "CREATE EXTENSION IF NOT EXISTS vector"
  ]
  name      = "gbrain"
  namespace = kubernetes_namespace.agents.metadata.0.name
}

module "app_gbrain" {
  source = "../../modules-harvester/service"

  depends_on = [module.db_init_gbrain]

  cluster_name = var.cluster_name
  containers = {
    gbrain = {
      command = ["/bin/sh", "-c"]
      args = [
        "gbrain init --non-interactive --url \"$DATABASE_URL\" --embedding-model ollama:${var.gbrain.embedding_model} --embedding-dimensions ${var.gbrain.embedding_dimensions} && exec gbrain serve --http --port 7333 --bind 0.0.0.0 --public-url https://gbrain.${var.tailscale_tailnet}"
      ]
      environment = {
        DATABASE_URL             = "postgres://gbrain:${random_password.gbrain_database_user.result}@gbrain-postgres:5432/gbrain"
        GBRAIN_HTTP_CORS_ORIGIN  = "https://gbrain.${var.tailscale_tailnet}"
        GBRAIN_QUERY_EXPANSION  = "off"
        OLLAMA_API_KEY          = var.gbrain.infersec_api_key
        OLLAMA_BASE_URL         = var.gbrain.infersec_api_base_url
        SYNC_INTERVAL           = "60"
        TZ                      = "Europe/Helsinki"
      }
      image = local.images.gbrain
      longhorn_mounts = {
        brain = {
          container_path  = "/data/brain"
          storage_request = "20Gi"
        }
        home = {
          container_path  = "/root/.gbrain"
          storage_request = "10Gi"
        }
      }
      ports = [
        {
          container          = 7333
          internal_hostname  = "gbrain"
          service            = 80
          tailscale_hostname = "gbrain"
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "gbrain"
  namespace              = kubernetes_namespace.agents.metadata.0.name
  replicas               = local.deployments_enabled.service ? 1 : 0
}
