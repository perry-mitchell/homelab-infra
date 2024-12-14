resource "kubernetes_storage_class" "storage_root" {
    for_each = var.root_mounts

    metadata {
        name = "nfs-${each.value.storage_name}-${each.key}"
    }

    storage_provisioner = "nfs.csi.k8s.io"
    reclaim_policy = "Retain"
    volume_binding_mode = "Immediate"
    allow_volume_expansion = true

    parameters = {
        server = each.value.nfs_server
        share = each.value.nfs_export
        subDir = ""
        # subPath = ""
    }

    mount_options = [
        "nfsvers=4.1"
    ]
}

resource "kubernetes_persistent_volume_claim" "storage_root" {
    for_each = var.root_mounts

    metadata {
        name = "nfs-${each.value.storage_name}-${each.key}"
        namespace = var.namespace
        annotations = {
            application = var.name
        }
    }

    spec {
        access_modes = [each.value.read_only ? "ReadOnlyMany" : "ReadWriteMany"]
        storage_class_name = "nfs-${each.value.storage_name}-${each.key}"
        resources {
            requests = {
                storage = coalesce(each.value.storage_request, "50Gi")
            }
        }
    }
}
