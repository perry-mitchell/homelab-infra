locals {
  longhorn_mounts_raw = toset(flatten([
    for container_name, container in var.containers : [
      for storage_name, config in container.longhorn_mounts : {
        "${container_name}-${storage_name}" = {
          container_name  = container_name
          container_path  = config.container_path
          storage_name    = storage_name
          storage_request = config.storage_request
        }
      }
    ]
  ]))
  longhorn_mounts = merge(local.longhorn_mounts_raw...)
}

resource "kubernetes_persistent_volume_claim" "storage_longhorn" {
  for_each = local.longhorn_mounts

  metadata {
    name      = "longhorn-${each.key}"
    namespace = var.namespace
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "longhorn"
    resources {
      requests = {
        storage = each.value.storage_request
      }
    }
  }
}
