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
  postgres_postgis_service_name = "postgres-postgis"
  postgres_postgis_service_namespace = "datasources"
  postgres_postgis_service_hostname = "${local.postgres_postgis_service_name}.${local.postgres_postgis_service_namespace}.svc.cluster.local"
}

locals {
  redis_service_name = "redis"
  redis_service_namespace = "datasources"
  redis_service_hostname = "${local.redis_service_name}.${local.redis_service_namespace}.svc.cluster.local"
  redis_db_reservations = {
    immich = 1
    nextcloud = 2
    paperless = 3
  }
}
