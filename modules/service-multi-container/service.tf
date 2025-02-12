module "dns" {
    source = "../dns-name"
    for_each = var.containers

    cluster_fqdn = var.dns_config.cluster_fqdn
    host_ip = var.dns_config.host_ip
    subdomain_name = each.key
}

module "dns_tailscale" {
    source = "../dns-name"
    for_each = var.containers

    cluster_fqdn = var.tailscale.tailnet
    host_ip = var.tailscale.host_ip
    subdomain_name = each.key
}

resource "kubernetes_service" "local" {
    for_each = var.containers

    metadata {
        name = each.key
        namespace = var.namespace
    }

    spec {
        selector = {
            application = kubernetes_deployment.deployment.spec[0].template[0].metadata[0].labels.application
        }

        port {
            port        = each.value.service_port
            target_port = each.value.container_port
        }
    }
}

resource "kubernetes_service" "tailscale" {
    for_each = var.containers

    metadata {
        name = "${var.name}-tailscale-${each.key}"
        namespace = var.namespace
        annotations = {
            "tailscale.com/expose" = "true"
            "tailscale.com/hostname" = each.key
            "tailscale.com/https" = "true"
        }
    }

    spec {
        selector = {
            application = kubernetes_deployment.deployment.spec[0].template[0].metadata[0].labels.application
        }

        port {
            name        = "application"
            port        = each.value.service_port
            target_port = each.value.container_port
        }
    }
}

resource "kubernetes_ingress_v1" "local" {
    for_each = var.containers

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
            for_each = toset([
                module.dns[each.key].dns_name,
                module.dns_tailscale[each.key].dns_name
            ])

            content {
                host = rule.value

                http {
                    path {
                        path = "/"
                        path_type = "Prefix"

                        backend {
                            service {
                                name = kubernetes_service.local[each.key].metadata[0].name

                                port {
                                    number = kubernetes_service.local[each.key].spec[0].port[0].port
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
    for_each = var.containers

    metadata {
        name = "${var.name}-tailscale-${each.key}"
        namespace = var.namespace
        annotations = {}
    }

    spec {
        ingress_class_name = "tailscale"

        dynamic "rule" {
            for_each = toset([
                    module.dns_tailscale[each.key].dns_name
            ])

            content {
                host = rule.value

                http {
                    path {
                        path = "/"
                        path_type = "Prefix"

                        backend {
                            service {
                                name = kubernetes_service.tailscale[each.key].metadata[0].name

                                port {
                                    number = kubernetes_service.tailscale[each.key].spec[0].port[0].port
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
