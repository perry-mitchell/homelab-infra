resource "kubernetes_namespace" "dashboard" {
  metadata {
    name = "kubernetes-dashboard"
  }
}

resource "helm_release" "kubernetes_dashboard" {
    name       = "kubernetes-dashboard"
    namespace = resource.kubernetes_namespace.dashboard.metadata[0].name

    repository = "https://kubernetes.github.io/dashboard/"
    chart      = "kubernetes-dashboard"
    version    = "7.10.0"
    wait = true

    set {
        name = "kong.proxy.http.enabled"
        value = "true"
    }
}

resource "kubernetes_ingress_v1" "dashboard" {
    metadata {
        name = "dashboard-ingress"
    }

    depends_on = [ helm_release.kubernetes_dashboard ]

    spec {
        rule {
            host = "dashboard.acheron.local"

            http {
                path {
                    path = "/"
                    path_type = "Prefix"

                    backend {
                        service {
                            name = "kubernetes-dashboard-web"
                            port {
                                number = 8000
                            }
                        }
                    }
                }
            }
        }
    }
}
