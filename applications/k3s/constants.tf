locals {
  mariadb_service_name = "mariadb"
  mariadb_service_namespace = "datasources"
  mariadb_service_hostname = "${local.mariadb_service_name}.${local.mariadb_service_namespace}.svc.cluster.local"
}

locals {
  postgres_service_name = "postgres"
  postgres_service_namespace = "datasources"
  postgres_service_hostname = "${local.postgres_service_name}.${local.postgres_service_namespace}.svc.cluster.local"
}

locals {
  postgres_pgvecto_rs_service_name = "postgres-pgvecto-rs"
  postgres_pgvecto_rs_service_namespace = "datasources"
  postgres_pgvecto_rs_service_hostname = "${local.postgres_pgvecto_rs_service_name}.${local.postgres_pgvecto_rs_service_namespace}.svc.cluster.local"
}

locals {
  redis_service_name = "redis"
  redis_service_namespace = "datasources"
  redis_service_hostname = "${local.redis_service_name}.${local.redis_service_namespace}.svc.cluster.local"
  redis_db_reservations = {
    immich = 1
    nextcloud = 2
  }
}
