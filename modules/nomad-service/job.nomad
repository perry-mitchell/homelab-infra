job "${name}" {
    datacenters = ["${datacenter}"]
    type        = "service"

    group "application" {
        volume "appdata" {
            type            = "csi"
            source          = "${volume_id}"
            read_only       = false
            attachment_mode = "file-system"
            access_mode     = "multi-node-multi-writer"
        }

        task "application" {
            driver = "docker"

            config {
                image = "${image}"
                volumes = [
                    %{ for volume in volumes ~}
                    "$${NOMAD_ALLOC_DIR}/appdata/${name}/${volume.remote_directory}:${volume.container_directory}",
                    %{ endfor }
                ]
            }

            resources {
                cpu    = ${cpu}
                memory = ${memory}
            }

            volume_mount {
                volume = "appdata"
                destination = "$${NOMAD_ALLOC_DIR}/appdata"
                read_only = false
            }
        }
    }
}
