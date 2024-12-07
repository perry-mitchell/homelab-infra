resource "kubernetes_service" "service" {
    metadata {
        name = var.name
        namespace = var.namespace
        annotations = merge(
            {},
            var.tailscale != null && var.ingress_enabled ? {
                "tailscale.com/expose" = "true"
                "tailscale.com/hostname" = var.tailscale.hostname
            } : {}
        )
    }

    spec {
        selector = {
            application = kubernetes_deployment.deployment.spec[0].template[0].metadata[0].labels.application
        }

        port {
            port        = var.service_port
            target_port = var.container_port
        }
    }
}

module "dns" {
    source = "../dns-name"
    count = var.ingress_enabled ? 1 : 0

    cluster_fqdn = var.dns_config.cluster_fqdn
    host_ip = var.dns_config.host_ip
    subdomain_name = var.dns_config.subdomain_name
}

resource "kubernetes_ingress_v1" "service" {
    count = var.ingress_enabled ? 1 : 0

    metadata {
        name = var.name
        namespace = var.namespace
    }

    spec {
        ingress_class_name = "nginx"

        rule {
            host = module.dns[0].dns_name

            http {
                path {
                    path = "/"
                    path_type = "Prefix"

                    backend {
                        service {
                            name = kubernetes_service.service.metadata[0].name

                            port {
                                number = kubernetes_service.service.spec[0].port[0].port
                            }
                        }
                    }
                }
            }
        }
    }
}
