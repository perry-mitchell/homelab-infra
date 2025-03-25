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
        providers = {
            longhorn = {
                url = module.longhorn.frontend_internal_url
            }
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
                },
                {
                    "Zigbee2MQTT" = {
                        icon = "zigbee2mqtt"
                        href = "http://${module.app_z2m.host_tailscale}"
                        description = "Zigbee 2 MQTT interface"
                    }
                }
            ]
        },
        {
            Entertainment = [
                {
                    Plex = {
                        icon = "plex"
                        href = "${var.plex_url_base}/web/index.html"
                        description = "Movies, TV, Anime and kids media"
                        widget = {
                            type = "plex"
                            url = var.plex_url_base
                            key = var.plex_token
                        }
                    }
                },
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
                        href = "http://${module.app_arr_stack.host_tailscale["gluetun"]}"
                        description = "Torrent VPN gateway"
                        widget = {
                            type = "gluetun"
                            url = "http://${module.app_arr_stack.host_k8s["gluetun"]}"
                        }
                    }
                },
                {
                    Sonarr = {
                        icon = "sonarr"
                        href = "http://${module.app_arr_stack.host_tailscale["sonarr"]}"
                        description = "TV show indexing and download manager"
                        widget = {
                            type = "sonarr"
                            url = "http://${module.app_arr_stack.host_k8s["sonarr"]}"
                            key = var.sonarr_token
                            enableQueue = false
                        }
                    }
                },
                {
                    Radarr = {
                        icon = "radarr"
                        href = "http://${module.app_arr_stack.host_tailscale["radarr"]}"
                        description = "Movie indexing and download manager"
                        widget = {
                            type = "radarr"
                            url = "http://${module.app_arr_stack.host_k8s["radarr"]}"
                            key = var.radarr_token
                            enableQueue = false
                        }
                    }
                },
                {
                    Prowlarr = {
                        icon = "prowlarr"
                        href = "http://${module.app_arr_stack.host_tailscale["prowlarr"]}"
                        description = "Media index manager"
                        widget = {
                            type = "prowlarr"
                            url = "http://${module.app_arr_stack.host_k8s["prowlarr"]}"
                            key = var.prowlarr_token
                        }
                    }
                },
                {
                    Overseerr = {
                        icon = "overseerr"
                        href = "http://${module.app_overseerr.host_tailscale}"
                        description = "Media request manager"
                        widget = {
                            type = "overseerr"
                            url = "http://${module.app_overseerr.host_k8s}"
                            key = var.overseerr_token
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
                    PaperlessNGX = {
                        icon = "paperless-ngx"
                        href = "http://${module.app_paperless.host_tailscale}"
                        description = "Document processing and storage"
                        widget = {
                            type = "paperlessngx"
                            url = "http://${module.app_paperless.host_k8s}:80"
                            username = var.paperless_auth.admin_user
                            password = var.paperless_auth.admin_password
                        }
                    }
                },
                {
                    Nextcloud = {
                        icon = "nextcloud"
                        href = "http://${module.nextcloud_dns_tailscale.dns_name}"
                        description = "Synchronised storage"
                        widget = {
                            type = "nextcloud"
                            url = "http://${local.nextcloud_k8s_host}"
                            username = var.nextcloud_auth.username
                            password = var.nextcloud_auth.password
                        }
                    }
                }
            ]
        },
        {
            Business = [
                {
                    "Kimai" = {
                        icon = "kimai"
                        href = "http://${module.app_kimai.host_tailscale}"
                        description = "Time tracking and invoice management"
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
                },
                {
                    GitSave = {
                        icon = "github-light"
                        href = "http://${module.app_gitsave.host_tailscale}"
                        description = "Github repository backups"
                    }
                }
            ]
        },
        {
            Network = [
                {
                    PiHole = {
                        icon = "pi-hole"
                        href = var.pihole_admin_url
                        description = "DNS management and ad blocking"
                        widget = {
                            type = "pihole"
                            url = var.pihole_url
                            version = 5
                            key = var.pihole_api_key
                        }
                    }
                },
                {
                    Smokeping = {
                        icon = "smokeping"
                        href = "http://${module.app_smokeping.host_tailscale}"
                        description = "DNS/HTTP connectivity monitoring"
                    }
                },
                {
                    Unifi = {
                        icon = "ubiquiti"
                        href = var.unifi_url
                        description = "Unifi network management"
                        widget = {
                            type = "unifi"
                            url = var.unifi_url
                            username = var.unifi_auth.username
                            password = var.unifi_auth.password
                        }
                    }
                }
            ]
        }
    ])
    homepage_widgets = yamlencode([
        {
            longhorn = {
                expanded = true
                total = true
                labels = true
                nodes = true
            }
        }
        # {
        #     kubernetes: {
        #         cluster: {
        #             show: true,
        #             cpu: true,
        #             memory: true,
        #             showLabel: true,
        #             label: "k3s"
        #         },
        #         nodes: {
        #             show: true,
        #             cpu: true,
        #             memory: true,
        #             showLabel: true
        #         }
        #     }
        # }
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
    environment = {
        HOMEPAGE_ALLOWED_HOSTS = join(",", [
            join(".", ["home", var.tailscale_tailnet]),
            join(".", ["home", var.cluster_fqdn])
        ])
    }
    files = {
        "/app/config/bookmarks.yaml" = ""
        "/app/config/docker.yaml" = ""
        "/app/config/services.yaml" = local.homepage_services
        "/app/config/settings.yaml" = local.homepage_settings
        "/app/config/widgets.yaml" = local.homepage_widgets
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
