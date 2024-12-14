resource "helm_release" "nfs_csi" {
    name       = "nfs-${var.storage_name}"
    namespace  = "default"

    repository = "https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts"
    chart      = "csi-driver-nfs"
    version    = "4.9.0"
    wait       = true

    set {
        name = "controller.name"
        value = "csi-nfs-controller-${var.storage_name}"
    }

    set {
        name = "rbac.name"
        value = "nfs-${var.storage_name}"
    }

    set {
        name = "serviceAccount.controller"
        value = "nfs-sa-controller-${var.storage_name}"
    }

    set {
        name = "serviceAccount.node"
        value = "nfs-sa-node-${var.storage_name}"
    }

    set {
        name = "node.name"
        value = "csi-nfs-${var.storage_name}"
    }
}
