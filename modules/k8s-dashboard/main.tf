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
        namespace = resource.kubernetes_namespace.dashboard.metadata[0].name
        annotations = {
            "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS"
            "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
        }
    }

    depends_on = [ helm_release.kubernetes_dashboard ]

    spec {
        ingress_class_name = "nginx"

        rule {
            host = "dashboard.acheron.local"

            http {
                path {
                    path = "/"
                    path_type = "Prefix"

                    backend {
                        service {
                            name = "kubernetes-dashboard-kong-proxy"
                            port {
                                number = 443
                            }
                        }
                    }
                }
            }
        }
    }
}

resource "kubernetes_service_account" "admin_user" {
    metadata {
        name = "admin-user"
        namespace = resource.kubernetes_namespace.dashboard.metadata[0].name
    }
}

resource "kubernetes_cluster_role_binding" "admin_user" {
    metadata {
        name = "admin-user"
    }

    role_ref {
        api_group = "rbac.authorization.k8s.io"
        kind      = "ClusterRole"
        name      = "cluster-admin"
    }

    subject {
        kind      = "ServiceAccount"
        name      = "admin-user"
        namespace = resource.kubernetes_namespace.dashboard.metadata[0].name
    }
}

resource "kubernetes_secret" "admin_user" {
    metadata {
        name = "admin-user"
        namespace = resource.kubernetes_namespace.dashboard.metadata[0].name
        annotations = {
            "kubernetes.io/service-account.name" = "admin-user"
        }
    }

    type = "kubernetes.io/service-account-token"
}
