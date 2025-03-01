// Reference:
//  - https://nerdiverset.no/k8s-native-sidecar-with-vpn/
//  - https://github.com/qdm12/gluetun-wiki/pull/7
module "app_arr_stack" {
    source = "../../modules/service-multi-container"

    containers = {
        gluetun = {
            capabilities = ["NET_ADMIN"]
            container_port = 8000
            environment = {
                BLOCK_ADS = "off"
                BLOCK_MALICIOUS = "off"
                BLOCK_SURVEILLANCE = "off"
                DNS_UPDATE_PERIOD = "5m"
                DNS_KEEP_NAMESERVER = "on"
                DOT = "on"
                DOT_CACHING = "on"
                DOT_PROVIDERS = "cloudflare"
                DOT_IPV6 = "off"
                FIREWALL = "on"
                FIREWALL_INPUT_PORTS = join(",", [var.vpn_provider.endpoint_port, 8000, 8080, 8888, 8388])
                FIREWALL_OUTBOUND_SUBNETS = "10.42.0.0/15,192.168.201.0/24,192.168.0.0/24"
                FIREWALL_VPN_INPUT_PORTS = join(",", var.vpn_provider.inbound_ports)
                HEALTH_TARGET_ADDRESS = "github.com:443"
                OPENVPN_AUTH = "sha256"
                OPENVPN_CIPHERS = "AES-128-GCM"
                OPENVPN_PASSWORD = var.vpn_provider.password
                OPENVPN_USER = var.vpn_provider.username
                OPENVPN_PROTOCOL = "tcp"
                SERVER_HOSTNAMES = join(",", var.vpn_provider.server_hostnames)
                VPN_ENDPOINT_IP = var.vpn_provider.endpoint_ip
                VPN_ENDPOINT_PORT = "${var.vpn_provider.endpoint_port}"
                VPN_INTERFACE = "tun0"
                VPN_SERVICE_PROVIDER = var.vpn_provider.provider
                VPN_TYPE = "openvpn"
                TZ = "Europe/Helsinki"
            }
            image = {
                tag = "latest"
                uri = "qmcgaw/gluetun"
            }
            init = false
            longhorn_mounts = {
                config = {
                    container_path = "/gluetun"
                    storage_request = "5Gi"
                }
            }
            service_port = 80
        }
        prowlarr = {
            container_port = 9696
            environment = {
                PGID = "100"
                PUID = "99"
                TZ = "Europe/Helsinki"
            }
            image = {
                tag = "latest"
                uri = "lscr.io/linuxserver/prowlarr"
            }
            longhorn_mounts = {
                config = {
                    container_path = "/config"
                    storage_request = "10Gi"
                }
            }
            service_port = 80
        }
        sonarr = {
            container_port = 8989
            environment = {
                PGID = "100"
                PUID = "99"
                TZ = "Europe/Helsinki"
            }
            image = {
                tag = "latest"
                uri = "lscr.io/linuxserver/sonarr"
            }
            longhorn_mounts = {
                config = {
                    container_path = "/config"
                    storage_request = "10Gi"
                }
            }
            nfs_mounts = {
                entertainment = {
                    create_subdir = false
                    container_path = "/entertainment"
                    nfs_export = var.nfs_storage.entertainment.export
                    nfs_server = var.nfs_storage.entertainment.host
                    read_only = false
                    storage_request = "5Ti"
                }
            }
            service_port = 80
        }
        "torrent-entertainment" = {
            container_port = 8080
            environment = {
                PGID = "100"
                PUID = "99"
                TORRENTING_PORT = "6881"
                TZ = "Europe/Helsinki"
                WEBUI_PORT = "8080"
            }
            image = {
                tag = "latest"
                uri = "lscr.io/linuxserver/qbittorrent"
            }
            longhorn_mounts = {
                config = {
                    container_path = "/config"
                    storage_request = "10Gi"
                }
            }
            nfs_mounts = {
                entertainment = {
                    create_subdir = false
                    container_path = "/entertainment"
                    nfs_export = var.nfs_storage.entertainment.export
                    nfs_server = var.nfs_storage.entertainment.host
                    read_only = false
                    storage_request = "500Gi"
                }
            }
            service_port = 80
        }
    }

    dns_config = {
        cluster_fqdn = var.cluster_fqdn
        host_ip = local.primary_ingress_ip
    }
    name = "arr"
    namespace = kubernetes_namespace.torrents.metadata[0].name
    tailscale = {
        host_ip = local.primary_ingress_ip
        tailnet = var.tailscale_tailnet
    }
}
