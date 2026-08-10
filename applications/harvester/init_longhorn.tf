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

resource "kubernetes_manifest" "longhorn_node_down_pod_deletion_policy" {
  manifest = {
    apiVersion = "longhorn.io/v1beta2"
    kind       = "Setting"
    metadata = {
      name      = "node-down-pod-deletion-policy"
      namespace = "longhorn-system"
    }
    value = "delete-both-statefulset-and-deployment-pod"
  }

  field_manager {
    force_conflicts = true
  }
}
