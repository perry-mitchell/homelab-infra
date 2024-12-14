module "nfs_storage_subdir" {
  source = "../../modules/k8s-nfs-subdir"

  for_each = var.nfs_storage

  name = each.key
  nfs_export = each.value.export
  nfs_server = each.value.host
  path_pattern = each.value.path_pattern
}
