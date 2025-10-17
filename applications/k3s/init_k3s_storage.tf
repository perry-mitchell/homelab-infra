module "nfs_storage_subdir" {
  source = "../../modules/k8s-nfs-subdir"

  for_each = var.nfs_storage

  name         = each.key
  nfs_export   = each.value.export
  nfs_server   = each.value.host
  path_pattern = each.value.path_pattern
}

module "nfs_storage_export" {
  source = "../../modules/k8s-nfs-export"

  storage_name = "k3s-root"
}

resource "helm_release" "csi_smb" {
  name      = "csi-driver-smb"
  namespace = "kube-system"

  repository = "https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/master/charts"
  chart      = "csi-driver-smb"
  version    = "v1.17.0"
  wait       = true
}

module "longhorn" {
  source = "../../modules/k8s-longhorn"

  tailscale = {
    hostname = "longhorn"
    host_ip  = local.primary_ingress_ip
    tailnet  = var.tailscale_tailnet
  }
}
