# module "app_tautulli" {
#     source = "../../modules/service2"

#     depends_on = [ module.nfs_storage_subdir ]

#     container_port = 8181
#     dns_config = {
#         cluster_fqdn = var.cluster_fqdn
#         host_ip = local.primary_ingress_ip
#         subdomain_name = "tautulli"
#     }
#     environment = {
#         PGID = "100"
#         PUID = "99"
#         TZ = "Europe/Helsinki"
#     }
#     image = {
#         tag = "latest"
#         uri = "lscr.io/linuxserver/tautulli"
#     }
#     longhorn_mounts = {
#         data = {
#             container_path = "/config"
#             storage_request = "10Gi"
#         }
#     }
#     name = "tautulli"
#     namespace = kubernetes_namespace.entertainment.metadata[0].name
#     replicas = 0
#     service_port = 80
#     tailscale = {
#         hostname = "tautulli"
#         host_ip = local.primary_ingress_ip
#         tailnet = var.tailscale_tailnet
#     }
# }
