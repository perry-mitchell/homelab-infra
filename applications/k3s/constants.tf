locals {
  mariadb_service_name = "mariadb"
  mariadb_service_namespace = "datasources"
  mariadb_service_hostname = "${local.mariadb_service_name}.${local.mariadb_service_namespace}.svc.cluster.local"
}
