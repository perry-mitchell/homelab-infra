job "storage-node" {
    datacenters = ["${datacenter}"]
    type        = "system"

    group "node" {
        task "node" {
            driver = "docker"

            config {
                image = "registry.gitlab.com/rocketduck/csi-plugin-nfs:0.7.0"

                args = [
                    "--type=node",
                    "--node-id=$${attr.unique.hostname}",
                    "--nfs-server=${nfs_server}:${nfs_mount}",
                    "--mount-options=defaults",
                ]

                network_mode = "host"

                privileged = true
            }

            csi_plugin {
                id        = "nfs-${plugin_name}"
                type      = "node"
                mount_dir = "/csi"
            }

            resources {
                cpu    = 200
                memory = 128
            }
        }
    }
}
