resource "random_password" "flowise_db_password" {
  length  = 32
  special = false
}

resource "random_password" "flowise_token_secret" {
  length  = 32
  special = false
}

module "db_init_flowise" {
  source = "../../modules/postgres-init"

  depends_on = [module.db_postgres]

  create_database = "flowise"
  create_user = {
    password = random_password.flowise_db_password.result
    username = "flowise"
  }
  db_host     = local.postgres_service_hostname
  db_password = var.db_postgres_root
  db_username = "root"
  name        = "flowise"
}

locals {
  flowise_public_url = "https://flowise.${var.tailscale_tailnet}"
}

module "app_flowise" {
  source = "../../modules/service3"

  depends_on = [module.longhorn, module.db_init_flowise]

  container_port = 3000
  dns_config = {
    cluster_fqdn   = var.cluster_fqdn
    host_ip        = local.primary_ingress_ip
    subdomain_name = "flowise"
  }
  environment = {
    APP_URL           = local.flowise_public_url
    BLOB_STORAGE_PATH = "/root/.flowise/storage"
    DATABASE_TYPE     = "postgres"
    DATABASE_PORT     = 5432
    DATABASE_HOST     = local.postgres_service_hostname
    DATABASE_NAME     = "flowise"
    DATABASE_USER     = "flowise"
    DATABASE_PASSWORD = random_password.flowise_db_password.result
    DATABASE_SSL      = "false"
    LOG_PATH          = "/root/.flowise/logs"
    PORT              = 3000
    SECRETKEY_PATH    = "/root/.flowise"
    TOKEN_HASH_SECRET = random_password.flowise_token_secret.result
  }
  image = {
    tag = "latest"
    uri = "flowiseai/flowise"
  }
  longhorn_mounts = {
    flowise = {
      container_path  = "/root/.flowise"
      storage_request = "100Gi"
    }
  }
  name         = "flowise"
  namespace    = kubernetes_namespace.ai.metadata[0].name
  service_port = 80
  tailscale = {
    hostname = "flowise"
    host_ip  = local.primary_ingress_ip
    tailnet  = var.tailscale_tailnet
  }
}
