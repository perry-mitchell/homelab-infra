module "app_whisper" {
    source = "../../modules/service"

    depends_on = [ module.nfs_storage_subdir ]

    container_port = 10300
    environment = {
        PGID = "100"
        PUID = "99"
        TZ = "Europe/Helsinki"
        WHISPER_MODEL = "base-int8"
        WHISPER_LANG = "en"
        WHISPER_BEAM = "4"
    }
    image = {
        tag = "latest"
        uri = "lscr.io/linuxserver/faster-whisper"
    }
    name = "whisper"
    namespace = kubernetes_namespace.smart_home.metadata[0].name
    service_port = 10300
    subdir_mounts = {
        config = {
            container_path = "/config"
            storage = "appdata"
            storage_request = "25Gi"
        }
    }
}

module "app_piper" {
    source = "../../modules/service"

    depends_on = [ module.nfs_storage_subdir ]

    container_port = 10200
    environment = {
        PGID = "100"
        PIPER_LENGTH = "1.0"
        PIPER_NOISE = "0.667"
        PIPER_NOISEW = "0.333"
        PIPER_VOICE = "en_GB-cori-high"
        PUID = "99"
        TZ = "Europe/Helsinki"
    }
    image = {
        tag = "latest"
        uri = "lscr.io/linuxserver/piper"
    }
    name = "piper"
    namespace = kubernetes_namespace.smart_home.metadata[0].name
    service_port = 10200
    subdir_mounts = {
        config = {
            container_path = "/config"
            storage = "appdata"
            storage_request = "25Gi"
        }
    }
}

module "app_homeassistant" {
    source = "../../modules/service2"

    depends_on = [ module.app_piper, module.app_whisper, module.longhorn ]

    capabilities = ["NET_RAW"]
    container_port = 8123
    dns_config = {
        cluster_fqdn = var.cluster_fqdn
        host_ip = local.primary_ingress_ip
        subdomain_name = "homeassistant"
    }
    environment = {
        PGID = "100"
        PUID = "99"
        TZ = "Europe/Helsinki"
    }
    image = {
        tag = "2025.2.5"
        uri = "lscr.io/linuxserver/homeassistant"
    }
    longhorn_mounts = {
        config = {
            container_path = "/config"
            storage_request = "25Gi"
        }
    }
    name = "homeassistant"
    namespace = kubernetes_namespace.smart_home.metadata[0].name
    service_port = 80
    tailscale = {
        hostname = "homeassistant"
        host_ip = local.primary_ingress_ip
        tailnet = var.tailscale_tailnet
    }
}
