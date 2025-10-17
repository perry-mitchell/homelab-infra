resource "kubernetes_manifest" "longhorn_backup_target" {
  manifest = {
    apiVersion = "longhorn.io/v1beta2"
    kind       = "BackupTarget"
    metadata = {
      name      = "default"
      namespace = "longhorn-system"
    }
    spec = {
      backupTargetURL  = "nfs://192.168.0.101:/mnt/user/longhorn-harvester"
      credentialSecret = ""
      pollInterval     = "5m0s"
    }
  }

  field_manager {
    force_conflicts = true
  }
}
