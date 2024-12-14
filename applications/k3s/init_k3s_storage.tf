module "nfs_storage" {
  source = "../../modules/k8s-nfs-provisioner"

  for_each = var.nfs_storage

  name = each.key
  nfs_export = each.value.export
  nfs_server = each.value.host
  path_pattern = each.value.path_pattern
}
