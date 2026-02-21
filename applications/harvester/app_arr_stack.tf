# Reference:
#  - https://nerdiverset.no/k8s-native-sidecar-with-vpn/
#  - https://github.com/qdm12/gluetun-wiki/pull/7

module "app_arr_stack" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    gluetun = {
      capabilities = ["NET_ADMIN"]
      environment = {
        BLOCK_ADS                 = "off"
        BLOCK_MALICIOUS           = "off"
        BLOCK_SURVEILLANCE        = "off"
        DNS_UPDATE_PERIOD         = "5m"
        DNS_KEEP_NAMESERVER       = "on"
        DOT                       = "on"
        DOT_CACHING               = "on"
        DOT_PROVIDERS             = "cloudflare"
        DOT_IPV6                  = "off"
        FIREWALL                  = "on"
        # FIREWALL_INPUT_PORTS      = join(",", [var.vpn_provider.endpoint_port, 8000, 8080, 8888, 8388])
        FIREWALL_INPUT_PORTS = join(",", [
          var.vpn_provider.endpoint_port,
          8000,   # gluetun
          8080,   # qbittorrent
          8888,
          8388,
          9696,   # prowlarr
          8989,   # sonarr
          7878,   # radarr
        ])
        FIREWALL_OUTBOUND_SUBNETS = "10.42.0.0/15,192.168.201.0/24,192.168.0.0/24,10.53.0.0/16"
        FIREWALL_VPN_INPUT_PORTS  = join(",", var.vpn_provider.inbound_ports)
        HEALTH_TARGET_ADDRESS     = "github.com:443"
        OPENVPN_AUTH              = "sha256"
        OPENVPN_CIPHERS           = "AES-128-GCM"
        OPENVPN_PASSWORD          = var.vpn_provider.password
        OPENVPN_USER              = var.vpn_provider.username
        OPENVPN_PROTOCOL          = "tcp"
        SERVER_HOSTNAMES          = join(",", var.vpn_provider.server_hostnames)
        VPN_ENDPOINT_IP           = var.vpn_provider.endpoint_ip
        VPN_ENDPOINT_PORT         = "${var.vpn_provider.endpoint_port}"
        VPN_INTERFACE             = "tun0"
        VPN_SERVICE_PROVIDER      = var.vpn_provider.provider
        VPN_TYPE                  = "openvpn"
        TZ                        = "Europe/Helsinki"
      }
      image = local.images.gluetun
      longhorn_mounts = {
        config = {
          container_path  = "/gluetun"
          storage_request = "5Gi"
        }
      }
      ports = [{
        container          = 8000
        service            = 80
        tailscale_hostname = "gluetun"
      }]
    }
    prowlarr = {
      environment = {
        PGID = "100"
        PUID = "99"
        TZ   = "Europe/Helsinki"
      }
      image = local.images.prowlarr
      longhorn_mounts = {
        config = {
          container_path  = "/config"
          storage_request = "10Gi"
        }
      }
      ports = [{
        container          = 9696
        service            = 80
        tailscale_hostname = "prowlarr"
      }]
    }
    sonarr = {
      environment = {
        PGID = "100"
        PUID = "99"
        TZ   = "Europe/Helsinki"
      }
      image = local.images.sonarr
      longhorn_mounts = {
        config = {
          container_path  = "/config"
          storage_request = "10Gi"
        }
      }
      nfs_mounts = {
        entertainment = {
          create_subdir   = false
          container_path  = "/entertainment"
          nfs_export      = var.nfs_storage.entertainment.export
          nfs_server      = var.nfs_storage.entertainment.host
          read_only       = false
          storage_request = "5Ti"
        }
      }
      ports = [{
        container          = 8989
        service            = 80
        tailscale_hostname = "sonarr"
      }]
    }
    radarr = {
      environment = {
        PGID = "100"
        PUID = "99"
        TZ   = "Europe/Helsinki"
      }
      image = local.images.radarr
      longhorn_mounts = {
        config = {
          container_path  = "/config"
          storage_request = "10Gi"
        }
      }
      nfs_mounts = {
        entertainment = {
          create_subdir   = false
          container_path  = "/entertainment"
          nfs_export      = var.nfs_storage.entertainment.export
          nfs_server      = var.nfs_storage.entertainment.host
          read_only       = false
          storage_request = "5Ti"
        }
      }
      ports = [{
        container          = 7878
        service            = 80
        tailscale_hostname = "radarr"
      }]
    }
    "torrent-entertainment" = {
      environment = {
        PGID            = "100"
        PUID            = "99"
        TORRENTING_PORT = "6881"
        TZ              = "Europe/Helsinki"
        WEBUI_PORT      = "8080"
      }
      image = local.images.qbittorrent
      longhorn_mounts = {
        config = {
          container_path  = "/config"
          storage_request = "10Gi"
        }
      }
      nfs_mounts = {
        entertainment = {
          create_subdir   = false
          container_path  = "/entertainment"
          nfs_export      = var.nfs_storage.entertainment.export
          nfs_server      = var.nfs_storage.entertainment.host
          read_only       = false
          storage_request = "500Gi"
        }
      }
      ports = [{
        container          = 8080
        service            = 80
        tailscale_hostname = "torrent-entertainment"
      }]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "arr"
  namespace              = kubernetes_namespace.torrenting.metadata.0.name
  replicas               = local.deployments_enabled.service ? 1 : 0
}
