locals {
  public_ports = merge([
    for container_name, container in var.containers : {
      for idx, port in container.ports : "${container_name}-${port.public_access.hostname}" => {
        container_name    = container_name
        container_port    = port.container
        service_port      = port.service
        hostname          = port.public_access.hostname
        public_access     = port.public_access
      }
      if port.public_access != null
    }
  ]...)
}

locals {
  public_name_sanitized = replace(lower(var.name), "/[^a-z0-9-]/", "-")
}

resource "kubernetes_service" "public" {
  for_each = local.public_ports

  metadata {
    name        = "${local.public_name_sanitized}-${replace(lower(each.key), "/[^a-z0-9-]/", "-")}-public"
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

    type = "ClusterIP"
  }
}

locals {
  public_ingress_class = try(
    [for port in local.public_ports : port.ingress_class][0],
    var.public_ingress_class
  )
}

resource "kubernetes_ingress_v1" "public" {
  for_each = local.public_ports

  metadata {
    name        = "${local.public_name_sanitized}-${replace(lower(each.key), "/[^a-z0-9-]/", "-")}-public"
    namespace   = var.namespace
    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
      "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
    }
  }

  spec {
    ingress_class_name = local.public_ingress_class

    tls {
      hosts = [
        each.value.hostname
      ]
      secret_name = "${local.public_name_sanitized}-${replace(lower(each.key), "/[^a-z0-9-]/", "-")}-public-tls"
    }

    rule {
      host = each.value.hostname

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.public[each.key].metadata[0].name

              port {
                number = kubernetes_service.public[each.key].spec[0].port[0].port
              }
            }
          }
        }
      }
    }
  }
}
