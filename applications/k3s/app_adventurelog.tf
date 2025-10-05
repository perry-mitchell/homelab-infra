# locals {
#   adventurelog_frontend_url = "http://adventurelog.${var.tailscale_tailnet}"
#   adventurelog_backend_url = "http://adventurelog-svr.${var.tailscale_tailnet}"
# }

# resource "random_password" "adventurelog_database_user" {
#     length = 32
#     special = false
# }

# module "db_init_adventurelog" {
#     source = "../../modules/postgres-init"

#     depends_on = [ module.db_postgres_postgis ]

#     create_database = "adventurelog"
#     create_user = {
#         password = random_password.adventurelog_database_user.result
#         username = "adventurelog"
#     }
#     db_host = local.postgres_postgis_service_hostname
#     db_password = var.db_postgres_postgis_root
#     db_username = "root"
#     name = "adventurelog"
# }

# resource "random_password" "adventurelog_secret_key" {
#     length = 32
#     special = false
# }

# module "app_adventurelog_backend" {
#     source = "../../modules/service"

#     depends_on = [ module.db_init_adventurelog, module.nfs_storage_subdir ]

#     container_port = 80
#     dns_config = {
#         cluster_fqdn = var.cluster_fqdn
#         host_ip = local.primary_ingress_ip
#         subdomain_name = "adventurelog-svr"
#     }
#     environment = {
#         PGHOST = local.postgres_postgis_service_hostname
#         PGDATABASE = "adventurelog"
#         PGUSER = "adventurelog"
#         PGPASSWORD = random_password.adventurelog_database_user.result
#         SECRET_KEY = random_password.adventurelog_secret_key.result
#         PUBLIC_URL = local.adventurelog_backend_url
#         CSRF_TRUSTED_ORIGINS = join(",", [local.adventurelog_frontend_url, local.adventurelog_backend_url])
#         DEBUG = "True"
#         FRONTEND_URL = local.adventurelog_frontend_url
#         DJANGO_ADMIN_EMAIL = var.admin_email
#         DJANGO_ADMIN_USERNAME = "admin"
#         DJANGO_ADMIN_PASSWORD = "admin"
#     }
#     files = {
#         "/etc/nginx/nginx.conf" = file("${path.module}/config/adventurelog/nginx.conf")
#     }
#     image = {
#         tag = "latest"
#         uri = "ghcr.io/seanmorley15/adventurelog-backend"
#     }
#     name = "adventurelog-svr"
#     namespace = kubernetes_namespace.travel.metadata[0].name
#     service_port = 80
#     subdir_mounts = {
#         data = {
#             container_path = "/code/media/"
#             storage = "appdata"
#             storage_request = "30Gi"
#         }
#     }
#     tailscale = {
#         hostname = "adventurelog-svr"
#         host_ip = local.primary_ingress_ip
#         tailnet = var.tailscale_tailnet
#     }
# }

# module "app_adventurelog_frontend" {
#     source = "../../modules/service"

#     depends_on = [ module.app_adventurelog_backend ]

#     container_port = 3000
#     dns_config = {
#         cluster_fqdn = var.cluster_fqdn
#         host_ip = local.primary_ingress_ip
#         subdomain_name = "adventurelog"
#     }
#     environment = {
#         ORIGIN = local.adventurelog_frontend_url
#         BODY_SIZE_LIMIT = "Infinity"
#     }
#     image = {
#         tag = "latest"
#         uri = "ghcr.io/seanmorley15/adventurelog-frontend"
#     }
#     name = "adventurelog"
#     namespace = kubernetes_namespace.travel.metadata[0].name
#     service_port = 80
#     tailscale = {
#         hostname = "adventurelog"
#         host_ip = local.primary_ingress_ip
#         tailnet = var.tailscale_tailnet
#     }
# }
