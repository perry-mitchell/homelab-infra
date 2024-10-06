job "${name}" {
    datacenters = ["${datacenter}"]
    type        = "service"

    group "application" {
        volume "tailscale_state" {
            type            = "csi"
            source          = "daemon_${name}_state"
            read_only       = false
            attachment_mode = "file-system"
            access_mode     = "multi-node-multi-writer"
        }

        task "${name}" {
            driver = "docker"

            config {
                image        = "tailscale/tailscale:latest"
                privileged   = true
                hostname     = "${tailscale_hostname}"
                network_mode = "bridge"
                volumes      = [
                    "/dev/net/tun:/dev/net/tun"
                ]
                cap_add      = ["NET_ADMIN", "SYS_MODULE"]
            }

            resources {
                cpu    = ${cpu}
                memory = ${memory}
            }

            env = {
                TS_AUTHKEY    = "${tailscale_auth_key}"
                TS_EXTRA_ARGS = "--advertise-tags=tag:container --accept-routes --advertise-exit-node"
                TS_HOSTNAME   = "${tailscale_hostname}"
                TS_ROUTES     = "${tailscale_routes}"
                TS_STATE_DIR  = "/var/lib/tailscale"
            }

            volume_mount {
                volume      = "tailscale_state"
                destination = "/var/lib/tailscale"
            }
        }
    }
}
