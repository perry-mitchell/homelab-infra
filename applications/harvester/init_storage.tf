resource "helm_release" "csi_smb" {
    name       = "csi-driver-smb"
    namespace = "kube-system"

    repository = "https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/master/charts"
    chart      = "csi-driver-smb"
    version    = "v1.17.0"
    wait       = true
}

module "nfs_storage_export" {
    source = "../../modules/k8s-nfs-export"

    storage_name = "torrens"
}
