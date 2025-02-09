resource "kubernetes_service" "service" {
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
