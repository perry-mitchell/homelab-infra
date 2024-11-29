resource "kubernetes_deployment" "deployment" {
    metadata {
        name = var.name
        namespace = var.namespace
    }

    spec {
        replicas = 1

        selector {
            match_labels = {
                application = var.name
            }
        }

        template {
            metadata {
                labels = {
                    application = var.name
                }
            }

            spec {
                container {
                    image = "${var.image.uri}:${var.image.tag}"
                    name  = var.name

                    dynamic "volume_mount" {
                        for_each = var.mounts

                        content {
                            name       = volume_mount.key
                            mount_path = volume_mount.value.container_path
                        }
                    }

                    dynamic "volume_mount" {
                        for_each = var.files

                        content {
                            name       = "${var.name}-static-files"
                            mount_path = volume_mount.key
                            sub_path   = replace(volume_mount.key, "/", "_")
                        }
                    }
                }

                dynamic "volume" {
                    for_each = var.mounts

                    content {
                        name = volume.key

                        persistent_volume_claim {
                            claim_name = kubernetes_persistent_volume_claim.storage[volume.key].metadata[0].name
                        }
                    }
                }

                dynamic "volume" {
                    for_each = length(var.files) > 0 ? [1] : []

                    content {
                        name = "${var.name}-static-files"

                        config_map {
                            name = "${var.name}-static-files"
                        }
                    }
                }
            }
        }
    }

    depends_on = [ kubernetes_config_map.static_files ]
}
