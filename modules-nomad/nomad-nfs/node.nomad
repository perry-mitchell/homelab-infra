job "storage-node" {
    datacenters = ["${datacenter}"]
    type        = "system"

    group "node" {
        task "plugin" {
            driver = "docker"

            config {
                image = "registry.k8s.io/sig-storage/nfsplugin:v4.8.0"

                args = [
                    "--v=5",
                    "--nodeid=$${attr.unique.hostname}",
                    "--endpoint=unix:///csi/csi.sock",
                    "--drivername=nfs.csi.k8s.io"
                ]

                privileged = true
            }

            csi_plugin {
                id        = "nfs-${plugin_name}"
                type      = "node"
                mount_dir = "/csi"
            }

            resources {
                cpu    = 75
                memory = 50
            }
        }
    }
}
