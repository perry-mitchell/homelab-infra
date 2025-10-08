// To renew access token:
// curl -X POST https://id.twitch.tv/oauth2/token -H 'Content-Type: application/x-www-form-urlencoded' -d 'grant_type=client_credentials&client_id=<client_id>&client_secret=<client_secret>'

# module "app_wdosg" {
#     source = "../../modules/service2"

#     depends_on = [ module.longhorn ]

#     container_port = 3001
#     dns_config = {
#         cluster_fqdn = var.cluster_fqdn
#         host_ip = local.primary_ingress_ip
#         subdomain_name = "wdosg"
#     }
#     environment = {
#         LOG_LEVEL = "info"
#         SERVER_FRIENDLY_URL = "http://wdosg.${var.tailscale_tailnet}"
#         TOKEN_SECRET = var.wdosg_auth.encryption_key
#         TWITCH_CLIENT_ID = var.wdosg_auth.twitch_client_id
#         TWITCH_APP_ACCESS_TOKEN = var.wdosg_auth.twitch_app_access_token
#     }
#     image = {
#         tag = "latest"
#         uri = "soulraven1980/wdosg"
#     }
#     longhorn_mounts = {
#         config = {
#             container_path = "/app/database"
#             storage_request = "10Gi"
#         }
#     }
#     name = "wdosg"
#     namespace = kubernetes_namespace.entertainment.metadata[0].name
#     nfs_mounts = {
#         library = {
#             create_subdir = true
#             container_path = "/app/wdosglibrary"
#             nfs_export = var.nfs_storage.appdata.export
#             nfs_server = var.nfs_storage.appdata.host
#             storage_request = "100Gi"
#         }
#     }
#     service_port = 80
#     tailscale = {
#         hostname = "wdosg"
#         host_ip = local.primary_ingress_ip
#         tailnet = var.tailscale_tailnet
#     }
# }
