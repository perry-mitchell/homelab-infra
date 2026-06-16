# resource "random_password" "gbrain_db_root" {
#   length  = 32
#   special = false
# }
#
# module "db_gbrain_postgres" {
#   source = "../../modules-harvester/service"
#
#   cluster_name = var.cluster_name
#   containers = {
#     "gbrain-postgres" = {
#       environment = {
#         PGDATA            = "/var/lib/postgresql/data"
#         POSTGRES_DB       = "gbrain"
#         POSTGRES_PASSWORD = random_password.gbrain_db_root.result
#         POSTGRES_USER     = "postgres"
#         TZ                = "Europe/Helsinki"
#       }
#       image = local.images.gbrain_postgres
#       longhorn_mounts = {
#         data = {
#           container_path  = "/var/lib/postgresql/data"
#           storage_request = "20Gi"
#         }
#       }
#       ports = [
#         {
#           container         = 5432
#           internal_hostname = "gbrain-postgres"
#           service           = 5432
#         }
#       ]
#     }
#   }
#   longhorn_storage_class = var.longhorn_storage_class
#   name                   = "gbrain-postgres"
#   namespace              = kubernetes_namespace.agents.metadata.0.name
#   replicas               = local.deployments_enabled.datasource ? 1 : 0
# }
#
# resource "random_password" "gbrain_database_user" {
#   length  = 32
#   special = false
# }
#
# module "db_init_gbrain" {
#   source = "../../modules-harvester/postgres-init"
#
#   depends_on = [module.db_gbrain_postgres]
#
#   create_database = "gbrain"
#   create_user = {
#     password = random_password.gbrain_database_user.result
#     username = "gbrain"
#   }
#   db_host     = "gbrain-postgres"
#   db_password = random_password.gbrain_db_root.result
#   db_username = "postgres"
#   extra_sql_lines = [
#     "ALTER USER gbrain WITH SUPERUSER",
#     "CREATE EXTENSION IF NOT EXISTS vector"
#   ]
#   name      = "gbrain"
#   namespace = kubernetes_namespace.agents.metadata.0.name
# }
#
# module "app_gbrain" {
#   source = "../../modules-harvester/service"
#
#   depends_on = [module.db_init_gbrain]
#
#   cluster_name = var.cluster_name
#   containers = {
#     gbrain = {
#       environment = {
#         DATABASE_URL      = "postgres://gbrain:${random_password.gbrain_database_user.result}@gbrain-postgres:5432/gbrain"
#         OPENAI_API_KEY    = var.gbrain.openai_api_key
#         ANTHROPIC_API_KEY = var.gbrain.anthropic_api_key
#         SYNC_INTERVAL     = "60"
#         TZ                = "Europe/Helsinki"
#       }
#       image = local.images.gbrain
#       longhorn_mounts = {
#         brain = {
#           container_path  = "/data/brain"
#           storage_request = "20Gi"
#         }
#       }
#       ports = [
#         {
#           container          = 7333
#           service            = 80
#           tailscale_hostname = "gbrain"
#         }
#       ]
#     }
#   }
#   longhorn_storage_class = var.longhorn_storage_class
#   name                   = "gbrain"
#   namespace              = kubernetes_namespace.agents.metadata.0.name
#   replicas               = local.deployments_enabled.service ? 1 : 0
# }
