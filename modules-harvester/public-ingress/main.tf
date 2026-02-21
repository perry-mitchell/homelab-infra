resource "kubernetes_namespace" "public_ingress" {
  metadata {
    name = "public-ingress"
  }
}

resource "helm_release" "public_ingress" {
  name      = "public-ingress"
  namespace = kubernetes_namespace.public_ingress.metadata[0].name

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.11.2"
  wait       = true

  set {
    name  = "controller.ingressClassResource.name"
    value = "nginx-public"
  }

  set {
    name  = "controller.ingressClassResource.controllerValue"
    value = "k8s.io/ingress-nginx-public"
  }

  set {
    name  = "controller.electionID"
    value = "public-ingress-leader"
  }

  set {
    name  = "controller.service.type"
    value = "NodePort"
  }

  set {
    name  = "controller.service.clusterIP"
    value = var.cluster_ip
  }

  set {
    name  = "controller.service.nodePorts.http"
    value = "30080"
  }

  set {
    name  = "controller.service.nodePorts.https"
    value = "30443"
  }
}
