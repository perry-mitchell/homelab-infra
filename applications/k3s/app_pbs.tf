# module "app_pbs" {
#     source = "../../modules/service2"

#     depends_on = [ module.longhorn ]

#     args = ["--mount type=tmpfs,destination=/run"]
#     command = ["runsvdir", "/runit"]
#     container_port = 8007
#     dns_config = {
#         cluster_fqdn = var.cluster_fqdn
#         host_ip = local.primary_ingress_ip
#         subdomain_name = "pbs"
#     }
#     environment = {
#         TZ = "Europe/Helsinki"
#     }
#     image = {
#         tag = "latest"
#         uri = "ayufan/proxmox-backup-server"
#     }
#     longhorn_mounts = {
#         etc = {
#             container_path = "/etc/proxmox-backup"
#             storage_request = "1Gi"
#         }
#         log = {
#             container_path = "/var/log/proxmox-backup"
#             storage_request = "10Gi"
#         }
#         lib = {
#             container_path = "/var/lib/proxmox-backup"
#             storage_request = "1Gi"
#         }
#     }
#     name = "pbs"
#     namespace = kubernetes_namespace.backup.metadata[0].name
#     nfs_mounts = {
#         backups = {
#             create_subdir = true
#             container_path = "/backups"
#             nfs_export = var.nfs_storage.backup.export
#             nfs_server = var.nfs_storage.backup.host
#             storage_request = "500Gi"
#         }
#     }
#     replicas = 0
#     service_port = 80
#     tailscale = {
#         hostname = "pbs"
#         host_ip = local.primary_ingress_ip
#         tailnet = var.tailscale_tailnet
#     }
#     temp_mounts = {
#         run = {
#             container_path = "/run"
#             size_limit = "256Mi"
#         }
#     }
# }
