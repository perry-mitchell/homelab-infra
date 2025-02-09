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
                dynamic "container" {
                    for_each = var.containers

                    content {
                        image = "${container.value.image.uri}:${container.value.image.tag}"
                        name = container.key

                        dynamic "security_context" {
                            for_each = (container.value.run_as != null || container.value.capabilities != null) ? [1] : []

                            content {
                                run_as_user                = container.value.run_as != null ? container.value.run_as.user : null
                                run_as_group               = container.value.run_as != null ? container.value.run_as.group : null
                                allow_privilege_escalation = container.value.run_as != null ? true : null

                                dynamic "capabilities" {
                                    for_each = container.value.capabilities != null ? [1] : []
                                    content {
                                        add = container.value.capabilities
                                    }
                                }
                            }
                        }

                        dynamic "env" {
                            for_each = container.value.environment

                            content {
                                name  = env.key
                                value = env.value
                            }
                        }

                        dynamic "volume_mount" {
                            for_each = local.nfs_mounts

                            content {
                                name       = volume_mount.key
                                mount_path = volume_mount.value.container_path
                            }
                        }
                    }
                }

                dynamic "volume" {
                    for_each = local.nfs_mounts

                    content {
                        name = volume.key

                        persistent_volume_claim {
                            claim_name = kubernetes_persistent_volume_claim.storage_nfs[volume.key].metadata[0].name
                        }
                    }
                }
            }
        }
    }

    depends_on = [ ]

    lifecycle {
        ignore_changes = [
            spec[0].template[0].metadata[0].annotations["kubectl.kubernetes.io/restartedAt"]
        ]
    }
}
