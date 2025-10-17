resource "kubernetes_persistent_volume_claim" "storage" {
  for_each = var.subdir_mounts

  metadata {
    name      = "${var.name}-${each.key}"
    namespace = var.namespace
    annotations = {
      application = var.name
    }
  }

  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "nfs-${each.value.storage}"
    resources {
      requests = {
        storage = coalesce(each.value.storage_request, "50Gi")
      }
    }
  }
}

