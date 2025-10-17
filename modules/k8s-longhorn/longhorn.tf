resource "helm_release" "longhorn" {
  name       = "longhorn"
  namespace  = "longhorn-system"
  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  version    = "1.8.0"

  wait             = true
  create_namespace = true

  values = [
    yamlencode({
      defaultSettings = {
        # Automatically cleanup when volumes are detached
        automaticallyCleanupWhenDetached = true

        # Delete pods when nodes go down (both StatefulSet and Deployment)
        nodeDownPodDeletionPolicy = "delete-both-statefulset-and-deployment-pod"

        # Faster node failure detection
        nodeDrainTimeout = "300" # 5 minutes instead of default 30

        # Block eviction only if it contains the last replica
        nodeDrainPolicy = "block-if-contains-last-replica"

        # Enable faster volume attachment/detachment
        disableSchedulingOnCordonedNode = true

        # Automatically detach volumes from failed nodes
        detachManuallyAttachedVolumesWhenCordoned = true

        # Reduce replica rebuild wait time
        replicaReplenishmentWaitInterval = "300" # 5 minutes

        # Faster engine upgrade timeout
        engineUpgradeTimeout = "300"
      }

      longhornManager = {
        tolerations = [
          {
            key               = "node.kubernetes.io/unreachable"
            operator          = "Exists"
            effect            = "NoExecute"
            tolerationSeconds = 300
          }
        ]
      }
    })
  ]
}
