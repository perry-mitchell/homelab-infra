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
                %{ for volume in volumes ~}
                mount {
                    type = "volume"
                    target = "${volume.container_directory}"
                    source = "appdata"
                }
                %{ endfor }
                %{ for mount in mounts ~}
                mount {
                    type = "bind"
                    source = "local${mount.directory}"
                    target = "${mount.directory}"
                }
                %{ endfor }
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

            env = {
                %{ for key, value in environment }
                "${key}" = "${value}"
                %{ endfor }
            }

            %{ if volume_id != null }
            volume_mount {
                volume = "appdata"
                destination = "$${NOMAD_ALLOC_DIR}/appdata"
                read_only = false
            }
            %{ endif }

            %{ for mount in mounts ~}
                %{ for file in mount.files ~}
                template {
                    data = <<EOF
${file.contents}
EOF
                    destination = "local${mount.directory}/${file.filename}"
                }
                %{ endfor }
            %{ endfor }
        }
    }
}
