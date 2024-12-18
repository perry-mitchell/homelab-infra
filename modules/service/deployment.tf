resource "kubernetes_deployment" "deployment" {
    metadata {
        name = var.name
        namespace = var.namespace
    }

    spec {
        replicas = var.replicas

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
                dynamic "security_context" {
                    for_each = var.run_as != null ? [1] : []

                    content {
                        run_as_user = var.run_as.user
                        run_as_group = var.run_as.group
                        fs_group = var.run_as.group
                    }
                }

                container {
                    image = "${var.image.uri}:${var.image.tag}"
                    name  = var.name
                    command = var.command

                    dynamic "env" {
                        for_each = var.environment

                        content {
                            name  = env.key
                            value = env.value
                        }
                    }

                    dynamic "volume_mount" {
                        for_each = var.subdir_mounts

                        content {
                            name       = volume_mount.key
                            mount_path = volume_mount.value.container_path
                        }
                    }

                    dynamic "volume_mount" {
                        for_each = local.root_mounts

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
                    for_each = var.subdir_mounts

                    content {
                        name = volume.key

                        persistent_volume_claim {
                            claim_name = kubernetes_persistent_volume_claim.storage[volume.key].metadata[0].name
                        }
                    }
                }

                dynamic "volume" {
                    for_each = local.root_mounts

                    content {
                        name = volume.key

                        persistent_volume_claim {
                            claim_name = kubernetes_persistent_volume_claim.storage_root[volume.key].metadata[0].name
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
