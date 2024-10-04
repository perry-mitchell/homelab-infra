job "${name}" {
    datacenters = ["${datacenter}"]
    type        = "service"

    group "application" {
        %{ if volume_id != null }
        volume "appdata" {
            type            = "csi"
            source          = "${volume_id}"
            read_only       = false
            attachment_mode = "file-system"
            access_mode     = "multi-node-multi-writer"
        }
        %{ endif }

        network {
            %{ for ext, int in ports }
            port "port_${ext}" {
                static = ${ext}
                to = ${int}
            }
            %{ endfor }
        }

        task "application" {
            driver = "docker"

            config {
                image = "${image}"
                ports = [
                    %{ for ext, int in ports }
                    "port_${ext}"
                    %{ endfor }
                ]
                volumes = [
                    %{ for volume in volumes ~}
                    "$${NOMAD_ALLOC_DIR}/appdata/${name}/${volume.remote_directory}:${volume.container_directory}",
                    %{ endfor }
                ]
            }

            %{ for ext, int in ports }
            service {
                name = "${name}-${ext}"
                port = "port_${ext}"
            }
            %{ endfor }

            resources {
                cpu    = ${cpu}
                memory = ${memory}
            }

            %{ if volume_id != null }
            volume_mount {
                volume = "appdata"
                destination = "$${NOMAD_ALLOC_DIR}/appdata"
                read_only = false
            }
            %{ endif }
        }
    }
}
