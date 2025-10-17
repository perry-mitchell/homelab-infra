locals {
  longhorn_mounts = {
    for name, mount in var.longhorn_mounts : name => {
      container_path  = mount.container_path
      storage_name    = name
      storage_request = mount.storage_request
    }
  }
}

resource "kubernetes_persistent_volume_claim" "storage_longhorn" {
  for_each = local.longhorn_mounts

  metadata {
    name      = "tailscale-${each.value.storage_name}"
    namespace = var.namespace
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.longhorn_storage_class
    resources {
      requests = {
        storage = each.value.storage_request
      }
    }
  }

  lifecycle {
    ignore_changes = [
      metadata.0.labels
    ]
  }
}
