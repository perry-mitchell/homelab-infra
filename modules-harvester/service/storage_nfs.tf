locals {
    nfs_mount_subdir_prefix = "nfsdynamic"
    nfs_mounts_raw = toset(flatten([
        for container_name, container in var.containers : [
            for storage_name, config in container.nfs_mounts : {
                "${container_name}-${storage_name}" = {
                    container_name = container_name
                    container_path = config.container_path
                    storage_name = storage_name
                    storage_request = config.storage_request
                    read_only = config.read_only
                    reclaim = "Retain"
                    server = config.nfs_server
                    share = config.create_subdir ? config.nfs_export : regex("^(.+)/([^/]+)/?$", config.nfs_export)[0]
                    sub_dir = config.create_subdir ? "${local.nfs_mount_subdir_prefix}-${var.namespace}-${container_name}-${storage_name}" : regex("^(.+)/([^/]+)/?$", config.nfs_export)[1]
                }
            }
        ]
    ]))
    nfs_mounts = merge(local.nfs_mounts_raw...)
}

resource "kubernetes_storage_class" "storage_nfs" {
    for_each = local.nfs_mounts

    metadata {
        name = "${var.cluster_name}-${each.key}"
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
        name = "${var.cluster_name}-${each.key}"
        namespace = var.namespace
        annotations = {
            application = each.value.container_name
        }
    }

    spec {
        access_modes = [each.value.read_only ? "ReadOnlyMany" : "ReadWriteMany"]
        storage_class_name = "nfs-${each.key}"
        resources {
            requests = {
                storage = each.value.storage_request
            }
        }
    }
}
