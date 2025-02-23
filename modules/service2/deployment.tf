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

                host_network = var.host_network
                dns_policy = var.host_network ? "ClusterFirstWithHostNet" : "ClusterFirst"
                share_process_namespace = var.share_process_namespace

                container {
                    image = "${var.image.uri}:${var.image.tag}"
                    name  = var.name
                    command = var.command
                    args = var.args

                    dynamic "security_context" {
                        for_each = (var.run_as != null || var.capabilities != null || var.privileged != false) ? [1] : []

                        content {
                            run_as_user                = var.run_as != null ? var.run_as.user : null
                            run_as_group               = var.run_as != null ? var.run_as.group : null
                            allow_privilege_escalation = var.run_as != null ? true : null
                            privileged                 = var.privileged

                            dynamic "capabilities" {
                                for_each = var.capabilities != null ? [1] : []
                                content {
                                    add = var.capabilities
                                }
                            }
                        }
                    }

                    dynamic "env" {
                        for_each = var.environment

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

                    dynamic "volume_mount" {
                        for_each = local.samba_mounts

                        content {
                            name       = "samba-${volume_mount.key}"
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
                    for_each = local.nfs_mounts

                    content {
                        name = volume.key

                        persistent_volume_claim {
                            claim_name = kubernetes_persistent_volume_claim.storage_nfs[volume.key].metadata[0].name
                        }
                    }
                }

                dynamic "volume" {
                    for_each = local.samba_mounts

                    content {
                        name = "samba-${volume.key}"

                        persistent_volume_claim {
                            claim_name = kubernetes_persistent_volume_claim.storage_samba[volume.key].metadata[0].name
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

    lifecycle {
        ignore_changes = [
            spec[0].template[0].metadata[0].annotations["kubectl.kubernetes.io/restartedAt"]
        ]
    }
}
