resource "kubernetes_namespace" "ingress" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "helm_release" "nginx_ingress" {
    name       = "ingress-nginx"
    namespace = resource.kubernetes_namespace.ingress.metadata[0].name

    repository = "https://kubernetes.github.io/ingress-nginx"
    chart      = "ingress-nginx"
    version = "4.11.2"
    wait = true

    set {
        name  = "controller.service.type"
        value = "LoadBalancer"
    }

    set {
        name  = "controller.service.ports.http"
        value = "80"
    }

    set {
        name  = "controller.service.ports.https"
        value = "443"
    }
}
