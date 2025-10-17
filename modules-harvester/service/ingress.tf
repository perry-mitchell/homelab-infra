locals {
  # Flatten all ports from all containers into a single map
  all_ports = merge([
    for container_name, container in var.containers : {
      for idx, port in container.ports : "${container_name}-${port.hostname}" => {
        container_name = container_name
        container_port = port.container
        service_port   = port.service
        hostname       = port.hostname
      }
    }
  ]...)
}

resource "kubernetes_service" "tailscale" {
  for_each = local.all_ports

  metadata {
    name        = "${var.name}-${each.key}"
    namespace   = var.namespace
    annotations = {}
  }

  spec {
    selector = {
      application = kubernetes_deployment.deployment.spec[0].template[0].metadata[0].labels.application
    }

    port {
      name        = each.value.service_port == 80 ? "http" : "application"
      port        = each.value.service_port
      target_port = each.value.container_port
    }
  }
}

resource "kubernetes_ingress_v1" "tailscale" {
  for_each = local.all_ports

  metadata {
    name        = "${var.name}-${each.key}"
    namespace   = var.namespace
    annotations = {}
  }

  spec {
    ingress_class_name = "tailscale"

    tls {
      hosts = [
        each.value.hostname
      ]
      secret_name = "${var.name}-${each.key}-tls"
    }

    rule {
      host = each.value.hostname

      http {
        path {
          path      = "/"
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
