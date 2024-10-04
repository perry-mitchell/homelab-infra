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

        network {
            port "http" {
                // dynamic = 8000
                // static = 8080  # Or use "dynamic = 8080" for dynamic allocation
            }
        }

        task "application" {
            driver = "docker"

            config {
                image = "${image}"
                ports = [
                    "http"
                ]
                port_map {
                    http = 80
                }
                volumes = [
                    %{ for volume in volumes ~}
                    "$${NOMAD_ALLOC_DIR}/appdata/${name}/${volume.remote_directory}:${volume.container_directory}",
                    %{ endfor }
                ]
            }

            service {
                name = "${name}"
                port = "http"
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
