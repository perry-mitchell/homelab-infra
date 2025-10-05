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
                    for_each = {
                        for name, container in var.containers : name => container
                        if try(container.init, false) == false
                    }

                    content {
                        image = "${container.value.image.uri}:${container.value.image.tag}"
                        name = container.key
                        image_pull_policy = "Always"
                        # restart_policy = container.value.restart_policy

                        args = container.value.args
                        command = container.value.command

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
                            for_each = {
                                for mount_name, mount in local.nfs_mounts : mount_name => mount
                                if mount.container_name == container.key
                            }

                            content {
                                name       = volume_mount.key
                                mount_path = volume_mount.value.container_path
                            }
                        }

                        dynamic "volume_mount" {
                            for_each = {
                                for mount_name, mount in local.longhorn_mounts : mount_name => mount
                                if mount.container_name == container.key
                            }

                            content {
                                name       = "${var.cluster_name}-${volume_mount.key}"
                                mount_path = volume_mount.value.container_path
                            }
                        }

                        dynamic "volume_mount" {
                            for_each = container.value.static_mounts != null ? container.value.static_mounts : {}

                            content {
                                name       = "${var.name}-${container.key}-static-files"
                                mount_path = volume_mount.key
                                sub_path   = replace(volume_mount.key, "/", "_")
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

                dynamic "volume" {
                    for_each = local.longhorn_mounts

                    content {
                        name = "${var.cluster_name}-${volume.key}"

                        persistent_volume_claim {
                            claim_name = kubernetes_persistent_volume_claim.storage_longhorn[volume.key].metadata[0].name
                        }
                    }
                }

                dynamic "volume" {
                    for_each = {
                        for container_name, container in var.containers :
                        container_name => container
                        if container.static_mounts != null && length(container.static_mounts) > 0
                    }

                    content {
                        name = "${var.name}-${volume.key}-static-files"

                        config_map {
                            name = kubernetes_config_map.static_files[volume.key].metadata[0].name
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

    timeouts {
        create = "5m"
        update = "3m"
        delete = "5m"
    }
}
