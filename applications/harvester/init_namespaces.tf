resource "kubernetes_namespace" "dns" {
    metadata {
        name = "dns"
    }
}

resource "kubernetes_namespace" "monitoring" {
    metadata {
        name = "monitoring"
    }
}
