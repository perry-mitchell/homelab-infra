resource "kubernetes_persistent_volume_claim" "tailscale" {
    metadata {
        name = "tailscale-subnet-a"
        namespace = "default"
        annotations = {
            application = "tailscale-subnet-a"
        }
    }

    spec {
        access_modes = ["ReadWriteMany"]
        storage_class_name = "nfs-${var.storage}"
        resources {
            requests = {
                storage = "5Gi"
            }
        }
    }
}
