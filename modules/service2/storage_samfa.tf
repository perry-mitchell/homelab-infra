locals {
    samba_mount_subdir_prefix = "samba-subdir"
    samba_mounts = {
        for name, mount in var.samba_mounts : name => {
            container_path = mount.container_path
            gid = mount.gid
            password = mount.password
            read_only = mount.read_only
            reclaim = "Retain"
            source = "//${mount.server}/${mount.share}"
            storage_name = name
            storage_request = mount.storage_request
            sub_dir = mount.create_subdir ? "${local.samba_mount_subdir_prefix}-${var.namespace}-${var.name}-${name}" : null
            uid = mount.uid
            username = mount.username
            volume_handle = mount.create_subdir ? "${mount.server}/${mount.share}#${local.samba_mount_subdir_prefix}-${var.namespace}-${var.name}-${name}#${var.namespace}-${var.name}-${name}" : "${mount.server}/${mount.share}##${var.namespace}-${var.name}-${name}"
        }
    }
}

resource "kubernetes_secret" "samba_share_auth" {
    for_each = local.samba_mounts

    metadata {
        name = "samba-auth-${var.name}-${each.value.storage_name}"
        namespace = var.namespace
    }

    data = {
        password = each.value.password
        username = each.value.username
    }

    type = "Opaque"
}

resource "kubernetes_storage_class" "storage_samba" {
    for_each = local.samba_mounts

    metadata {
        name = "samba-${var.name}-${each.value.storage_name}"
    }

    storage_provisioner = "smb.csi.k8s.io"
    reclaim_policy     = each.value.reclaim
    volume_binding_mode = "Immediate"
    allow_volume_expansion = true

    parameters = {
        source = each.value.source
        subDir = each.value.sub_dir
        onDelete = lower(each.value.reclaim)
        "csi.storage.k8s.io/provisioner-secret-name" = kubernetes_secret.samba_share_auth[each.key].metadata.0.name
        "csi.storage.k8s.io/provisioner-secret-namespace" = var.namespace
        "csi.storage.k8s.io/node-stage-secret-name" = kubernetes_secret.samba_share_auth[each.key].metadata.0.name
        "csi.storage.k8s.io/node-stage-secret-namespace" = var.namespace
    }

    mount_options = concat(
        [
            "dir_mode=0777",
            "file_mode=0777",
            "noserverino",
            "noperm",
            "mfsymlinks",
            "cache=none",
            "nobrl",
            "actimeo=0",
            "vers=3.1.1",
            "hard",
            "nosharesock"
        ],
        each.value.gid != null ? ["gid=${each.value.gid}"] : [],
        each.value.uid != null ? ["uid=${each.value.uid}"] : []
    )
}

resource "kubernetes_persistent_volume_claim" "storage_samba" {
    for_each = local.samba_mounts

    metadata {
        name = "samba-${var.name}-${each.value.storage_name}"
        namespace = var.namespace
    }

    spec {
        access_modes = [each.value.read_only ? "ReadOnlyMany" : "ReadWriteMany"]
        storage_class_name = kubernetes_storage_class.storage_samba[each.key].metadata.0.name

        resources {
            requests = {
                storage = each.value.storage_request
            }
        }
    }
}

# resource "kubernetes_persistent_volume" "storage_samba" {
#     for_each = local.samba_mounts

#     metadata {
#         name = "samba-${var.name}-${each.value.storage_name}"
#         annotations = {
#             "pv.kubernetes.io/provisioned-by" = "smb.csi.k8s.io"
#         }
#     }

#     spec {
#         capacity = {
#             storage = each.value.storage_request
#         }
#         access_modes = ["ReadWriteMany"]
#         persistent_volume_reclaim_policy = each.value.reclaim
#         storage_class_name = "smb"
#         mount_options = [
#             "dir_mode=0777",
#             "file_mode=0777"
#         ]
#         persistent_volume_source {
#             csi {
#                 driver = "smb.csi.k8s.io"
#                 volume_handle = each.value.volume_handle
#                 read_only = each.value.read_only
#                 volume_attributes = {
#                     source = each.value.source
#                     subDir = each.value.sub_dir
#                 }
#                 node_stage_secret_ref {
#                     name = kubernetes_secret.samba_share_auth[each.key].metadata.0.name
#                     namespace = var.namespace
#                 }
#             }
#         }
#     }
# }

# resource "kubernetes_persistent_volume_claim" "storage_samba" {
#     for_each = local.samba_mounts

#     metadata {
#         name = "samba-${var.name}-${each.value.storage_name}"
#         namespace = var.namespace
#         annotations = {
#             application = var.name
#         }
#     }

#     spec {
#         access_modes = [each.value.read_only ? "ReadOnlyMany" : "ReadWriteMany"]
#         storage_class_name = "smb"
#         volume_name = "samba-${var.name}-${each.value.storage_name}"
#         resources {
#             requests = {
#                 storage = each.value.storage_request
#             }
#         }
#     }
# }
