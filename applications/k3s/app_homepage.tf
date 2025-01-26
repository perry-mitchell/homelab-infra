locals {
    homepage_settings = yamlencode({
        title = "Perry Mitchell @ Home"
        description = "Homelab services and links"
        theme = "dark"
        favicon = "https://perrymitchell.net/favicon.ico"
        background = {
            image = "/images/australia-01.jpg"
            opacity = 70
            blur = "sm"
        }
    })
    homepage_services = yamlencode([
        {
            "Smart Home" = [
                {
                    "Home Assistant" = {
                        icon = "home-assistant"
                        href = "http://${module.app_homeassistant.host_tailscale}"
                        description = "Smart home management"
                        widget = {
                            type = "homeassistant"
                            url = "http://${module.app_homeassistant.host_k8s}"
                            key = var.homeassistant_api_key
                        }
                    }
                }
            ]
        },
        {
            Entertainment = [
                {
                    Tautulli = {
                        icon = "tautulli"
                        href = "http://${module.app_tautulli.host_tailscale}"
                        description = "Plex Media Server management and analytics"
                        widget = {
                            type = "tautulli"
                            url = "http://${module.app_tautulli.host_k8s}"
                            key = var.tautulli_api_key
                            enableUser = true
                        }
                    }
                }
            ]
        },
        {
            Torrents = [
                {
                    Gluetun = {
                        icon = "gluetun"
                        href = "http://${module.app_gluetun.host_tailscale}"
                        description = "Torrent VPN gateway"
                        widget = {
                            type = "gluetun"
                            url = "http://${module.app_gluetun.host_k8s}"
                        }
                    }
                }
            ]
        },
        {
            Media = [
                {
                    Immich = {
                        icon = "immich"
                        href = "http://${module.app_immich.host_tailscale}"
                        description = "Photo library and backup"
                        widget = {
                            type = "immich"
                            url = "http://${module.app_immich.host_k8s}"
                            key = var.immich_api_keys.homepage
                            version = 2
                        }
                    }
                },
                {
                    Nextcloud = {
                        icon = "nextcloud"
                        href = "http://${module.app_nextcloud.host_tailscale}"
                        description = "Synchronised storage"
                        widget = {
                            type = "nextcloud"
                            url = "http://${module.app_nextcloud.host_k8s}"
                            username = var.nextcloud_auth.username
                            password = var.nextcloud_auth.password
                        }
                    }
                },
                {
                    Homebox = {
                        icon = "homebox"
                        href = "http://${module.app_homebox.host_tailscale}"
                        description = "Asset tracking system"
                        widget = {
                            type = "homebox"
                            url = "http://${module.app_homebox.host_k8s}"
                            username = var.homebox_auth.username
                            password = var.homebox_auth.password
                        }
                    }
                }
            ]
        },
        {
            Backup = [
                {
                    Kopia = {
                        icon = "kopia"
                        href = "http://${module.app_kopia.host_tailscale}"
                        description = "Unraid storage backup"
                        widget = {
                            type = "kopia"
                            url = "http://${module.app_kopia.host_k8s}"
                            username = var.kopia_admin.username
                            password = var.kopia_admin.password
                        }
                    }
                }
            ]
        }
    ])
}

module "app_homepage" {
    source = "../../modules/service"

    depends_on = [ module.nfs_storage_subdir ]

    container_port = 3000
    dns_config = {
        cluster_fqdn = var.cluster_fqdn
        host_ip = local.primary_ingress_ip
        subdomain_name = "home"
    }
    files = {
        "/app/config/bookmarks.yaml" = ""
        "/app/config/docker.yaml" = ""
        "/app/config/services.yaml" = local.homepage_services
        "/app/config/settings.yaml" = local.homepage_settings
        "/app/config/widgets.yaml" = ""
    }
    image = {
        tag = "latest"
        uri = "ghcr.io/gethomepage/homepage"
    }
    name = "homepage"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    service_port = 80
    subdir_mounts = {
        "images" = {
            container_path = "/app/public/images"
            storage = "appdata"
            storage_request = "5Gi"
        }
    }
    tailscale = {
        hostname = "home"
        host_ip = local.primary_ingress_ip
        tailnet = var.tailscale_tailnet
    }
}
