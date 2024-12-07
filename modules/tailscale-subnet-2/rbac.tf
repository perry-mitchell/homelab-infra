resource "kubernetes_service_account" "tailscale" {
    metadata {
        name = "tailscale-a"
        namespace = "default"
    }
}

resource "kubernetes_role" "tailscale" {
    metadata {
        name = "tailscale-a"
        namespace = "default"
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
        name = "tailscale-a"
        namespace = "default"
    }

    subject {
        kind = "ServiceAccount"
        name = "tailscale-a"
    }

    role_ref {
        kind      = "Role"
        name      = "tailscale-a"
        api_group = "rbac.authorization.k8s.io"
    }
}
