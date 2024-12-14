resource "helm_release" "nfs_external_provisioner" {
    name       = "nfs-${var.name}"
    namespace  = "default"

    repository = "https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/"
    chart      = "nfs-subdir-external-provisioner"
    version    = "4.0.18"
    wait       = true

    set {
        name  = "nfs.server"
        value = var.nfs_server
    }

    set {
        name  = "nfs.path"
        value = var.nfs_export
    }

    set {
        name = "storageClass.name"
        value = "nfs-${var.name}"
    }

    set {
        name = "storageClass.provisionerName"
        value = "k8s-sigs.io/${var.name}-nfs-subdir-external-provisioner"
    }

    set {
        name = "storageClass.pathPattern"
        value = var.path_pattern
    }
}
