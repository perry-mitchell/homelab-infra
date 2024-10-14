job "${name}" {
    datacenters = ["${datacenter}"]
    type        = "service"

    group "application" {
        %{ for _, volume in volumes }
        volume "${volume.mount_name}" {
            type = "csi"
            source = "service_${name}_${volume.mount_name}"
            read_only       = false
            attachment_mode = "file-system"
            access_mode     = "multi-node-multi-writer"
        }
        %{ endfor }

        network {
            %{ for ext, int in ports }
            port "port_${ext}" {
                static = ${ext}
                to = ${int}
            }
            %{ endfor }
        }

        task "${name}" {
            driver = "docker"

            config {
                image = "${image}"
                ports = [
                    %{ for ext, int in ports }
                    "port_${ext}"
                    %{ endfor }
                ]
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

            %{ for _, volume in volumes }
            volume_mount {
                volume = "${volume.mount_name}"
                destination = "${volume.container_directory}"
            }
            %{ endfor }

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
