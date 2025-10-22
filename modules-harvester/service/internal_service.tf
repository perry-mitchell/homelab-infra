locals {
  # Flatten all ports from all containers into a single map
  internal_ports = merge([
    for container_name, container in var.containers : {
      for idx, port in container.ports : "${container_name}-${port.internal_hostname}" => {
        container_name = container_name
        container_port = port.container
        service_port   = port.service
        hostname       = port.internal_hostname
      }
      if port.internal_hostname != null
    }
  ]...)
}

resource "kubernetes_service" "internal" {
  for_each = local.internal_ports

  metadata {
    name        = "${each.value.hostname}"
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
