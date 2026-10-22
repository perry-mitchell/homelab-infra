locals {
  companion_satellite_config = jsonencode({
    remoteProtocol = "tcp"
    remoteIp       = "companion-sat-link.${kubernetes_namespace.smart_home.metadata.0.name}.svc.cluster.local"
    remotePort     = 16622
    restEnabled    = true
    restPort       = 9999
    mdnsEnabled    = false
    surfacePluginsEnabled = {
      "elgato-stream-deck" = true
    }
  })
}

module "app_companion" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    companion = {
      environment = {
        TZ = "Europe/Helsinki"
      }
      fs_group = 1000
      image = local.images.companion
      longhorn_mounts = {
        config = {
          container_path  = "/companion"
          storage_request = "2Gi"
        }
      }
      ports = [
        {
          container          = 8000
          service            = 80
          tailscale_hostname = "companion"
        },
        {
          # Satellite (TCP) link target for stream deck surfaces
          container         = 16622
          internal_hostname = "companion-sat-link"
          service           = 16622
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "companion"
  namespace              = kubernetes_namespace.smart_home.metadata.0.name
  replicas               = local.deployments_enabled.service ? 1 : 0
}

module "app_companion_satellite" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    satellite = {
      command = [
        "sh",
        "-c",
        "mkdir -p /config && printf '%s' '${local.companion_satellite_config}' > /config/satellite.json && exec node /app/satellite/dist/main.js /config/satellite.json"
      ]
      environment = {
        TZ = "Europe/Helsinki"
      }
      host_mounts = {
        devices = {
          host_path  = "/dev"
          mount_path = "/dev"
        }
      }
      image = local.images.companion_satellite
      ports = [
        {
          container          = 9999
          service            = 80
          tailscale_hostname = "companion-satellite"
        }
      ]
      privileged = true
      run_as = {
        user  = 0
        group = 0
      }
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "companion-satellite"
  namespace              = kubernetes_namespace.smart_home.metadata.0.name
  node_selector = {
    # The node the stream deck is attached to
    "kubernetes.io/hostname" = "torrens"
  }
  replicas = local.deployments_enabled.service ? 1 : 0
}
