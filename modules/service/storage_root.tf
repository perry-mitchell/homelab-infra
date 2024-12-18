locals {
    root_mounts = {
        for name, mount in var.root_mounts : name => {
            container_path = mount.container_path
            storage_name = mount.storage_name
            storage_request = mount.storage_request
            read_only = mount.read_only
            server = mount.nfs_server
            share = regex("^(.+)/([^/]+)/?$", mount.nfs_export)[0]
            sub_dir = regex("^(.+)/([^/]+)/?$", mount.nfs_export)[1]
        }
    }
}

resource "kubernetes_storage_class" "storage_root" {
    for_each = local.root_mounts

    metadata {
        name = "nfs-${each.value.storage_name}-${each.key}"
    }

    storage_provisioner = "nfs.csi.k8s.io"
    reclaim_policy = "Retain"
    volume_binding_mode = "Immediate"
    allow_volume_expansion = true

    parameters = {
        server = each.value.server
        share = each.value.share
        subDir = each.value.sub_dir
    }

    mount_options = [
        "nfsvers=4.1"
    ]
}

resource "kubernetes_persistent_volume_claim" "storage_root" {
    for_each = local.root_mounts

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
