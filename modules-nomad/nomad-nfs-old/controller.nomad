job "storage-controller" {
    datacenters = ["${datacenter}"]
    type        = "service"

    group "controller" {
        task "controller" {
            driver = "docker"

            config {
                image = "registry.gitlab.com/rocketduck/csi-plugin-nfs:0.7.0"

                args = [
                    "--type=controller",
                    "--node-id=$${attr.unique.hostname}",
                    "--nfs-server=${nfs_server}:${nfs_mount}",
                    "--mount-options=defaults",
                ]

                network_mode = "host"

                privileged = true
            }

            csi_plugin {
                id        = "nfs-${plugin_name}"
                type      = "controller"
                mount_dir = "/csi"
            }

            resources {
                cpu    = 200
                memory = 128
            }
        }
    }
}
