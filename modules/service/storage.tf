resource "kubernetes_persistent_volume_claim" "storage" {
    for_each = var.mounts

    metadata {
        name = each.key
        namespace = var.namespace
        annotations = {
            application = var.name
        }
    }

    spec {
        access_modes = ["ReadWriteMany"]
        # storage_class_name = "nfs-client"
        storage_class_name = "nfs-${each.value.storage}"
        resources {
            requests = {
                storage = coalesce(each.value.storage_request, "50Gi")
            }
        }
    }
}

resource "kubernetes_config_map" "static_files" {
    count = length(var.files) > 0 ? 1 : 0

    metadata {
        name = "${var.name}-static-files"
        namespace = var.namespace
    }

    data = {
        for file_path, content in var.files : replace(file_path, "/", "_") => content
    }
}
