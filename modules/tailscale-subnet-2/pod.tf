resource "kubernetes_pod" "tailscale_subnet" {
    metadata {
        name = "tailscale-subnet-a"
    }

    spec {
        service_account_name = "tailscale-a"

        container {
            name  = "tailscale-a"
            image = "ghcr.io/tailscale/tailscale:latest"

            env {
                name = "TS_KUBE_SECRET"
                value = kubernetes_secret.tailscale_auth.metadata[0].name
            }

            env {
                name = "TS_AUTHKEY"
                value_from {
                    secret_key_ref {
                        name = kubernetes_secret.tailscale_auth.metadata[0].name
                        key  = "TS_AUTHKEY"
                    }
                }
            }

            env {
                name = "TS_EXTRA_ARGS"
                value = "--advertise-tags=tag:container --accept-routes --advertise-exit-node"
            }

            env {
                name = "TS_HOSTNAME"
                value = "tailscale-acheron-2"
            }

            env {
                name  = "TS_ROUTES"
                value = join(
                    ",",
                    concat(
                        ["10.42.0.0/16", "10.43.0.0/16"],
                        tolist(var.additional_cidrs)
                    )
                )
            }

            env {
                name = "TS_STATE_DIR"
                value = "/var/lib/tailscale"
            }

            env {
                name  = "TS_USERSPACE"
                value = "true"
            }

            volume_mount {
                name       = kubernetes_persistent_volume_claim.tailscale.metadata[0].name
                mount_path = "/var/lib/tailscale"
            }

            security_context {
                run_as_user  = 1000
                run_as_group = 1000
            }
        }

        volume {
            name = kubernetes_persistent_volume_claim.tailscale.metadata[0].name

            persistent_volume_claim {
                claim_name = kubernetes_persistent_volume_claim.tailscale.metadata[0].name
            }
        }
    }

    depends_on = [
        kubernetes_service_account.tailscale,
        kubernetes_role.tailscale,
        kubernetes_role_binding.tailscale,
        kubernetes_secret.tailscale_auth
    ]
}
