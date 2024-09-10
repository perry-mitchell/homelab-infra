job "storage-node" {
  datacenters = ["nak4"]
  type        = "system"

  group "node" {
    task "node" {
      driver = "docker"

      config {
        image = "registry.gitlab.com/rocketduck/csi-plugin-nfs:0.7.0"

        args = [
          "--type=node",
          "--node-id=${attr.unique.hostname}",
          "--nfs-server=192.168.0.100:/mnt/user/nomad_appdata",
          "--mount-options=defaults",
        ]

        network_mode = "host"

        privileged = true
      }

      csi_plugin {
        id        = "nfs"
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
