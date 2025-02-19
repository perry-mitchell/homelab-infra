resource "kubernetes_service" "local_alternate" {
    for_each = var.tailscale_port_alternatives

    metadata {
        name = "${var.name}-${each.key}"
        namespace = var.namespace
    }

    spec {
        selector = {
            application = kubernetes_deployment.deployment.spec[0].template[0].metadata[0].labels.application
        }

        port {
            port        = var.service_port
            target_port = each.value.port
        }
    }
}

resource "kubernetes_service" "tailscale_alternate" {
    for_each = var.tailscale != null ? var.tailscale_port_alternatives : {}

    metadata {
        name = "${var.name}-tailscale-alt-${each.key}"
        namespace = var.namespace
        annotations = merge(
            {
                "tailscale.com/expose" = "true"
                "tailscale.com/hostname" = each.value.hostname
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
            name        = each.key
            port        = var.service_port
            target_port = each.value.port
        }
    }
}

module "dns_alternate" {
    for_each = var.dns_config != null ? var.tailscale_port_alternatives : {}

    source = "../dns-name"

    cluster_fqdn = var.dns_config.cluster_fqdn
    host_ip = var.dns_config.host_ip
    subdomain_name = each.value.hostname
}

resource "kubernetes_ingress_v1" "local_alternate" {
    for_each = var.dns_config != null || var.tailscale != null ? var.tailscale_port_alternatives : {}

    metadata {
        name = "${var.name}-local-${each.key}"
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
                    module.dns_alternate[each.key].dns_name
                ] : [],
                var.tailscale != null ? [
                    module.dns_tailscale_alt[each.key].dns_name
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
                                name = kubernetes_service.local_alternate[each.key].metadata[0].name

                                port {
                                    number = kubernetes_service.local_alternate[each.key].spec[0].port[0].port
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

module "dns_tailscale_alt" {
    for_each = var.tailscale != null ? var.tailscale_port_alternatives : {}

    source = "../dns-name"

    cluster_fqdn = var.tailscale.tailnet
    host_ip = var.tailscale.host_ip
    subdomain_name = each.value.hostname
}

resource "kubernetes_ingress_v1" "tailscale_alternate" {
    for_each = var.tailscale != null ? var.tailscale_port_alternatives : {}

    metadata {
        name = "${var.name}-tailscale-alt-${each.key}"
        namespace = var.namespace
        annotations = {}
    }

    spec {
        ingress_class_name = "tailscale"

        dynamic "rule" {
            for_each = toset(
                var.tailscale != null ? [
                    module.dns_tailscale_alt[each.key].dns_name
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
                                name = kubernetes_service.tailscale_alternate[each.key].metadata[0].name

                                port {
                                    number = kubernetes_service.tailscale_alternate[each.key].spec[0].port[0].port
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
