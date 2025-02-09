# module "app_sonarr" {
#     source = "../../modules/service2"

#     depends_on = [ module.nfs_storage_subdir ]

#     container_port = 7745
#     dns_config = {
#         cluster_fqdn = var.cluster_fqdn
#         host_ip = local.primary_ingress_ip
#         subdomain_name = "sonarr"
#     }
#     environment = {
#         PGID = "100"
#         PUID = "99"
#         TZ = "Europe/Helsinki"
#     }
#     image = {
#         tag = "latest"
#         uri = "lscr.io/linuxserver/sonarr"
#     }
#     name = "sonarr"
#     namespace = kubernetes_namespace.torrents.metadata[0].name
#     nfs_mounts = {
#         config = {
#             container_path = "/config"
#             create_subdir = true
#             nfs_export = var.nfs_storage.appdata.export
#             nfs_server = var.nfs_storage.appdata.host
#             storage_request = "20Gi"
#         }
#         entertainment = {
#             container_path = "/tv"
#             create_subdir = false
#             nfs_export = var.nfs_storage.entertainment.export
#             nfs_server = var.nfs_storage.entertainment.host
#             storage_request = "5Ti"
#         }
#     }
#     # root_mounts = {
#     #     entertainment = {
#     #         container_path = "/tv"
#     #         nfs_export = var.nfs_storage.entertainment.export
#     #         nfs_server = var.nfs_storage.entertainment.host
#     #         read_only = false
#     #         storage_name = "k3s-root"
#     #         storage_request = "5Ti"
#     #     }
#     # }
#     service_port = 80
#     # subdir_mounts = {
#     #     config = {
#     #         container_path = "/config"
#     #         storage = "appdata"
#     #         storage_request = "20Gi"
#     #     }
#     # }
#     tailscale = {
#         hostname = "sonarr"
#         host_ip = local.primary_ingress_ip
#         tailnet = var.tailscale_tailnet
#     }
# }
