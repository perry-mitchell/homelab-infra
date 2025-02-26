# module "dns_tailscale" {
#     source = "../dns-name"
#     # count = var.tailscale != null ? 1 : 0

#     cluster_fqdn = var.tailscale.tailnet
#     host_ip = var.tailscale.host_ip
#     subdomain_name = var.tailscale.hostname
# }

# resource "kubernetes_ingress_v1" "tailscale" {
#     count = var.tailscale != null ? 1 : 0

#     metadata {
#         name = "longhorn-tailscale"
#         namespace = helm_release.longhorn.namespace
#         annotations = {}
#     }

#     spec {
#         ingress_class_name = "tailscale"

#         dynamic "rule" {
#             for_each = toset(
#                 var.tailscale != null ? [
#                     module.dns_tailscale[0].dns_name
#                 ] : []
#             )

#             content {
#                 host = rule.value

#                 http {
#                     path {
#                         path = "/"
#                         path_type = "Prefix"

#                         backend {
#                             service {
#                                 name = "longhorn-frontend"

#                                 port {
#                                     number = 80
#                                 }
#                             }
#                         }
#                     }
#                 }
#             }
#         }
#     }
# }
