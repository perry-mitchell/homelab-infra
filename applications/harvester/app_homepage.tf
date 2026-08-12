resource "kubernetes_service_account" "homepage" {
  metadata {
    name      = "homepage"
    namespace = kubernetes_namespace.organisation.metadata.0.name
  }
}

resource "kubernetes_cluster_role" "homepage" {
  metadata {
    name = "homepage"
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces", "nodes", "pods", "services"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["metrics.k8s.io"]
    resources  = ["nodes", "pods"]
    verbs      = ["get", "list"]
  }
}

resource "kubernetes_cluster_role_binding" "homepage" {
  metadata {
    name = "homepage"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.homepage.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.homepage.metadata[0].name
    namespace = kubernetes_namespace.organisation.metadata.0.name
  }
}

locals {
  homepage_services = [
    {
      Personal = [
        { "Hermes Agent" = { href = "https://hermes.${var.tailscale_tailnet}", icon = "mdi-robot-outline" } },
        { "Nextcloud" = { href = "https://nextcloud.${var.tailscale_tailnet}", icon = "nextcloud" } },
        { "Immich" = { href = "https://immich.${var.tailscale_tailnet}", icon = "immich" } },
        { "Vaultwarden" = { href = "https://vaultwarden.${var.tailscale_tailnet}", icon = "vaultwarden" } },
        { "Adventurelog" = { href = "https://adventurelog.${var.tailscale_tailnet}", icon = "adventurelog" } },
        { "Koillection" = { href = "https://collect.${var.tailscale_tailnet}", icon = "koillection" } },
        { "Mealie" = { href = "https://mealie.${var.tailscale_tailnet}", icon = "mealie" } },
        { "Paperless NGX" = { href = "https://paperless.${var.tailscale_tailnet}", icon = "paperless-ngx" } },
        { "Webtrees" = { href = "https://webtrees.${var.tailscale_tailnet}", icon = "webtrees" } },
        { "Healthchecks" = { href = "https://health.${var.tailscale_tailnet}", icon = "healthchecks" } },
        { "Pinchflat" = { href = "https://pinchflat.${var.tailscale_tailnet}", icon = "pinchflat" } },
        { "Tautulli" = { href = "https://tautulli.${var.tailscale_tailnet}", icon = "tautulli" } },
        { "Overseerr" = { href = "https://overseerr.${var.tailscale_tailnet}", icon = "overseerr" } },
        { "Sonarr" = { href = "https://sonarr.${var.tailscale_tailnet}", icon = "sonarr" } },
        { "Radarr" = { href = "https://radarr.${var.tailscale_tailnet}", icon = "radarr" } },
        { "Prowlarr" = { href = "https://prowlarr.${var.tailscale_tailnet}", icon = "prowlarr" } },
        { "qBittorrent" = { href = "https://torrent-entertainment.${var.tailscale_tailnet}", icon = "qbittorrent" } },
        { "Home Assistant" = { href = "https://homeassistant.${var.tailscale_tailnet}", icon = "home-assistant" } },
        { "Z2M" = { href = "https://z2m.${var.tailscale_tailnet}", icon = "zigbee2mqtt" } },
        { "Smokeping" = { href = "https://smokeping.${var.tailscale_tailnet}", icon = "smokeping" } },
        { "Maintenant" = { href = "https://maintenant.${var.tailscale_tailnet}", icon = "mdi-wrench-outline" } },
        { "Unraid" = { href = var.unraid_url, icon = "unraid" } },
      ]
    },
    {
      Professional = [
        { "Kimai" = { href = "https://kimai.${var.tailscale_tailnet}", icon = "kimai" } },
        { "Infersec" = { href = "https://infersec.${var.tailscale_tailnet}", icon = "mdi-shield-check-outline" } },
        { "Infersec Console" = { href = "https://console.infersec.ai", icon = "mdi-console" } },
      ]
    },
    {
      SEOAI = [
        for service in var.homepage_seoai : {
          (service.name) = { href = service.href, icon = service.icon }
        }
      ]
    },
  ]
}

module "app_homepage" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    homepage = {
      environment = {
        HOMEPAGE_ALLOWED_HOSTS = "home.${var.tailscale_tailnet}"
        HOSTNAME               = "0.0.0.0"
      }
      fs_group = 1000
      image    = local.images.homepage
      longhorn_mounts = {
        logs = {
          container_path  = "/app/config/logs"
          storage_request = "1Gi"
        }
      }
      binary_static_mounts = {
        "/app/public/images/background.jpg" = filebase64("${path.module}/assets/homepage-background.jpg")
      }
      ports = [
        {
          container          = 3000
          service            = 80
          tailscale_hostname = "home"
        }
      ]
      run_as = {
        user  = 1000
        group = 1000
      }
      static_mounts = {
        "/app/config/services.yaml"   = jsonencode(local.homepage_services)
        "/app/config/settings.yaml"   = file("${path.module}/config/homepage/settings.yaml")
        "/app/config/widgets.yaml"    = file("${path.module}/config/homepage/widgets.yaml")
        "/app/config/kubernetes.yaml" = file("${path.module}/config/homepage/kubernetes.yaml")
        "/app/config/bookmarks.yaml"  = file("${path.module}/config/homepage/bookmarks.yaml")
        "/app/config/docker.yaml"     = ""
        "/app/config/proxmox.yaml"    = ""
        "/app/config/custom.css"      = ""
        "/app/config/custom.js"       = ""
      }
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "homepage"
  namespace              = kubernetes_namespace.organisation.metadata.0.name
  replicas               = local.deployments_enabled.service ? 1 : 0
  service_account_name   = kubernetes_service_account.homepage.metadata[0].name
}
