module "app_arr_stack" {
    source = "../../modules/service-multi-container"

    containers = {
        gluetun = {
            capabilities = ["NET_ADMIN"]
            container_port = 8000
            environment = {
                DNS_UPDATE_PERIOD = "5m"
                DOT = "on"
                DOT_CACHING = "on"
                DOT_PROVIDERS = "cloudflare"
                FIREWALL = "on"
                FIREWALL_VPN_INPUT_PORTS = join(",", var.vpn_provider.inbound_ports)
                OPENVPN_VERBOSITY = "1"
                OPENVPN_VERSION = "2.5"
                OPENVPN_PASSWORD = var.vpn_provider.password
                OPENVPN_PROCESS_USER = "yes"
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
            nfs_mounts = {
                config = {
                    create_subdir = true
                    container_path = "/gluetun"
                    nfs_export = var.nfs_storage.appdata.export
                    nfs_server = var.nfs_storage.appdata.host
                    storage_request = "5Gi"
                }
            }
            service_port = 80
        }
    }

    name = "arr"
    namespace = kubernetes_namespace.torrents.metadata[0].name
}
