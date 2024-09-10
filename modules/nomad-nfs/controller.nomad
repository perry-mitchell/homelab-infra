job "storage-controller" {
  datacenters = ["nak4"]
  type        = "service"

  group "controller" {
    task "controller" {
      driver = "docker"

      config {
        image = "registry.gitlab.com/rocketduck/csi-plugin-nfs:0.7.0"

        args = [
          "--type=controller",
          "--node-id=${attr.unique.hostname}",
          "--nfs-server=192.168.0.100:/mnt/user/nomad_appdata",
          "--mount-options=defaults",
        ]

        network_mode = "host" # required so the mount works even after stopping the container

        privileged = true
      }

      csi_plugin {
        id        = "nfs" # Whatever you like, but node & controller config needs to match
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
