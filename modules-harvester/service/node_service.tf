locals {
  node_ports = merge([
    for container_name, container in var.containers : {
      for idx, port in container.ports : "${container_name}-${idx}" => {
        container_port = port.container
        service_port   = port.service
        node_port      = port.node_port
        protocol       = port.protocol
      }
      if port.node_port != null
    }
  ]...)
}

resource "kubernetes_service" "node" {
  count = length(local.node_ports) > 0 ? 1 : 0

  metadata {
    name        = "${var.name}-node"
    namespace   = var.namespace
    annotations = {}
  }

  spec {
    selector = {
      application = kubernetes_deployment.deployment.spec[0].template[0].metadata[0].labels.application
    }

    dynamic "port" {
      for_each = local.node_ports

      content {
        name        = "port-${port.value.node_port}"
        port        = port.value.service_port
        protocol    = port.value.protocol
        target_port = port.value.container_port
        node_port   = port.value.node_port
      }
    }

    type = "NodePort"
  }
}
