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
