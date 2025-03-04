locals {
  setup_local_service = var.container_port != null && var.service_port != null
  setup_local_ingress = local.setup_local_service && var.dns_config != null
  setup_tailscale = var.container_port != null && var.service_port != null && var.tailscale != null
}

module "dns" {
    source = "../dns-name"
    count = local.setup_local_ingress ? 1 : 0

    cluster_fqdn = var.dns_config.cluster_fqdn
    host_ip = var.dns_config.host_ip
    subdomain_name = var.dns_config.subdomain_name
}

module "dns_tailscale" {
    source = "../dns-name"
    count = local.setup_tailscale ? 1 : 0

    cluster_fqdn = var.tailscale.tailnet
    host_ip = var.tailscale.host_ip
    subdomain_name = var.tailscale.hostname
}

resource "kubernetes_service" "local" {
    count = local.setup_local_service ? 1 : 0

    metadata {
        name = var.name
        namespace = var.namespace
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

resource "kubernetes_service" "tailscale" {
    count = local.setup_tailscale ? 1 : 0

    metadata {
        name = "${var.name}-tailscale"
        namespace = var.namespace
        annotations = merge(
            {
                "tailscale.com/expose" = "true"
                "tailscale.com/hostname" = var.tailscale.hostname
                "tailscale.com/https" = "true"
            },
            try(var.tailscale.funnel, false) ? {
                "tailscale.com/funnel" = "true"
            } : {}
        )
    }

    spec {
        selector = {
            application = kubernetes_deployment.deployment.spec[0].template[0].metadata[0].labels.application
        }

        port {
            name        = var.service_port == 80 ? "http" : "application"
            port        = var.service_port
            target_port = var.container_port
        }
    }
}

resource "kubernetes_ingress_v1" "local" {
    count = local.setup_local_ingress ? 1 : 0

    metadata {
        name = "${var.name}-local"
        namespace = var.namespace
        annotations = {
            "nginx.ingress.kubernetes.io/proxy-body-size" = var.ingress_upload_size
        }
    }

    spec {
        ingress_class_name = "nginx"

        dynamic "rule" {
            for_each = toset(concat(
                var.dns_config != null ? [
                    module.dns[0].dns_name
                ] : [],
                var.tailscale != null ? [
                    module.dns_tailscale[0].dns_name
                ] : []
            ))

            content {
                host = rule.value

                http {
                    path {
                        path = "/"
                        path_type = "Prefix"

                        backend {
                            service {
                                name = kubernetes_service.local[0].metadata[0].name

                                port {
                                    number = kubernetes_service.local[0].spec[0].port[0].port
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

resource "kubernetes_ingress_v1" "tailscale" {
    count = local.setup_tailscale ? 1 : 0

    metadata {
        name = "${var.name}-tailscale"
        namespace = var.namespace
        annotations = {}
    }

    spec {
        ingress_class_name = "tailscale"

        dynamic "rule" {
            for_each = toset(
                var.tailscale != null ? [
                    module.dns_tailscale[0].dns_name
                ] : []
            )

            content {
                host = rule.value

                http {
                    path {
                        path = "/"
                        path_type = "Prefix"

                        backend {
                            service {
                                name = kubernetes_service.tailscale[0].metadata[0].name

                                port {
                                    number = kubernetes_service.tailscale[0].spec[0].port[0].port
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
