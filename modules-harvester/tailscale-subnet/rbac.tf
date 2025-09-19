resource "kubernetes_service_account" "tailscale" {
    metadata {
        name = "tailscale"
        namespace = var.namespace
    }
}

resource "kubernetes_role" "tailscale" {
    metadata {
        name = "tailscale"
        namespace = var.namespace
    }

    rule {
        api_groups     = [""]
        resource_names = [kubernetes_secret.tailscale_auth.metadata[0].name]
        resources      = ["secrets"]
        verbs          = ["get", "update", "patch"]
    }
}

resource "kubernetes_role_binding" "tailscale" {
    metadata {
        name = "tailscale"
        namespace = var.namespace
    }

    subject {
        kind = "ServiceAccount"
        name = "tailscale"
    }

    role_ref {
        kind      = "Role"
        name      = "tailscale"
        api_group = "rbac.authorization.k8s.io"
    }
}
