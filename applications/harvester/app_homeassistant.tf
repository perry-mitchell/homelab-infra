module "app_whisper" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    whisper = {
      environment = {
        PGID          = "100"
        PUID          = "99"
        TZ            = "Europe/Helsinki"
        WHISPER_MODEL = "large"
        WHISPER_LANG  = "en"
        WHISPER_BEAM  = "4"
      }
      image = {
        tag = "latest"
        uri = "lscr.io/linuxserver/faster-whisper"
      }
      longhorn_mounts = {
        config = {
          container_path  = "/config"
          storage_request = "10Gi"
        }
      }
      ports = [
        {
          container          = 10300
          internal_hostname = "whisper"
          service            = 10300
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "whisper"
  namespace              = kubernetes_namespace.smart_home.metadata.0.name
}

module "app_piper" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    piper = {
      environment = {
        PGID         = "100"
        PIPER_LENGTH = "1.0"
        PIPER_NOISE  = "0.667"
        PIPER_NOISEW = "0.333"
        PIPER_VOICE  = "en_GB-cori-high"
        PUID         = "99"
        TZ           = "Europe/Helsinki"
      }
      image = {
        tag = "latest"
        uri = "lscr.io/linuxserver/piper"
      }
      longhorn_mounts = {
        config = {
          container_path  = "/config"
          storage_request = "10Gi"
        }
      }
      ports = [
        {
          container          = 10200
          internal_hostname = "piper"
          service            = 10200
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "piper"
  namespace              = kubernetes_namespace.smart_home.metadata.0.name
}

module "app_homeassistant" {
  source = "../../modules-harvester/service"

  depends_on = [module.app_piper, module.app_whisper]

  cluster_name = var.cluster_name
  containers = {
    homeassistant = {
      capabilities   = ["NET_RAW"]
      environment = {
        PGID = "100"
        PUID = "99"
        TZ   = "Europe/Helsinki"
      }
      image = {
        tag = "2025.2.5"
        uri = "lscr.io/linuxserver/homeassistant"
      }
      longhorn_mounts = {
        config = {
          container_path  = "/config"
          storage_request = "25Gi"
        }
      }
      ports = [
        {
          container          = 8123
          service            = 80
          tailscale_hostname = "homeassistant"
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "homeassistant"
  namespace              = kubernetes_namespace.smart_home.metadata.0.name
  replicas               = 1
}
