resource "kubernetes_pod" "tailscale_subnet" {
  count = var.replicas

  metadata {
    name      = "tailscale-subnet"
    namespace = var.namespace
  }

  spec {
    service_account_name = "tailscale"

    container {
      name  = "tailscale"
      image = "ghcr.io/tailscale/tailscale:latest"

      env {
        name  = "TS_KUBE_SECRET"
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
        name  = "TS_EXTRA_ARGS"
        value = "--advertise-tags=tag:container --accept-routes --advertise-exit-node"
      }

      env {
        name  = "TS_HOSTNAME"
        value = var.hostname
      }

      env {
        name = "TS_ROUTES"
        value = join(
          ",",
          concat(
            ["10.42.0.0/16", "10.43.0.0/16"],
            tolist(var.additional_cidrs)
          )
        )
      }

      env {
        name  = "TS_STATE_DIR"
        value = "/var/lib/tailscale"
      }

      env {
        name  = "TS_USERSPACE"
        value = "true"
      }

      dynamic "volume_mount" {
        for_each = local.longhorn_mounts

        content {
          name       = "longhorn-${volume_mount.key}"
          mount_path = volume_mount.value.container_path
        }
      }

      security_context {
        run_as_user  = 1000
        run_as_group = 1000
      }
    }

    dynamic "volume" {
      for_each = local.longhorn_mounts

      content {
        name = "longhorn-${volume.key}"

        persistent_volume_claim {
          claim_name = kubernetes_persistent_volume_claim.storage_longhorn[volume.key].metadata[0].name
        }
      }
    }
  }

  depends_on = [
    kubernetes_service_account.tailscale,
    kubernetes_role.tailscale,
    kubernetes_role_binding.tailscale,
    kubernetes_secret.tailscale_auth
  ]

  lifecycle {
    ignore_changes = [
      metadata[0].annotations
    ]
  }
}

moved {
  from = kubernetes_pod.tailscale_subnet
  to = kubernetes_pod.tailscale_subnet.0
}
