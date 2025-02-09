locals {
    nfs_mount_subdir_prefix = "nfsdynamic"
    nfs_mounts = {
        for name, mount in var.nfs_mounts : name => {
            container_path = mount.container_path
            storage_name = name
            storage_request = mount.storage_request
            read_only = mount.read_only
            reclaim = "Retain"
            server = mount.nfs_server
            share = mount.create_subdir ? mount.nfs_export : regex("^(.+)/([^/]+)/?$", mount.nfs_export)[0]
            sub_dir = mount.create_subdir ? "${local.nfs_mount_subdir_prefix}-${var.namespace}-${var.name}-${name}" : regex("^(.+)/([^/]+)/?$", mount.nfs_export)[1]
        }
    }
}

resource "kubernetes_storage_class" "storage_nfs" {
    for_each = local.nfs_mounts

    metadata {
        name = "nfs-${var.name}-${each.value.storage_name}"
    }

    storage_provisioner = "nfs.csi.k8s.io"
    reclaim_policy = each.value.reclaim
    volume_binding_mode = "Immediate"
    allow_volume_expansion = true

    parameters = {
        server = each.value.server
        share = each.value.share
        subDir = each.value.sub_dir
    }
}

resource "kubernetes_persistent_volume_claim" "storage_nfs" {
    for_each = local.nfs_mounts

    metadata {
        name = "nfs-${var.name}-${each.value.storage_name}"
        namespace = var.namespace
        annotations = {
            application = var.name
        }
    }

    spec {
        access_modes = [each.value.read_only ? "ReadOnlyMany" : "ReadWriteMany"]
        storage_class_name = "nfs-${var.name}-${each.value.storage_name}"
        resources {
            requests = {
                storage = each.value.storage_request
            }
        }
    }
}
