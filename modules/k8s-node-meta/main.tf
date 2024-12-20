resource "kubernetes_labels" "node_labels" {
    count = length(var.labels) > 0 ? 1 : 0

    api_version = "v1"
    kind        = "Node"

    metadata {
        name = var.node_name
    }

    labels = var.labels
}
