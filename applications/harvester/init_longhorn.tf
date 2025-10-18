resource "kubernetes_manifest" "harvester_backup_target" {
  manifest = {
    apiVersion = "harvesterhci.io/v1beta1"
    kind       = "Setting"
    metadata = {
      name = "backup-target"
    }
    value = jsonencode({
      type     = "nfs"
      endpoint = "nfs://192.168.0.101:/mnt/user/longhorn-harvester"
    })
  }

  field_manager {
    force_conflicts = true
  }
}
