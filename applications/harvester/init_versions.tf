locals {
  # Terraform provider versions
  provider_versions = {
    b2         = "0.9.0"
    harvester  = "0.6.4"
    helm       = "2.16.1"
    htpasswd   = "~> 1.0"
    kubernetes = "2.33.0"
    namecheap  = ">= 2.2.0"
  }

  # Helm chart versions
  helm_versions = {
    csi_driver_smb = "v1.17.0"
    nextcloud      = "8.5.2"
  }

  # Container image definitions (uri + tag)
  images = {
    adventurelog = {
      uri = "ghcr.io/elliotwutingfeng/adventurelog"
      tag = "16-3.5"
    }
    adventurelog_db = {
      uri = "mariadb"
      tag = "latest"
    }
    atuin = {
      uri = "ghcr.io/elliotwutingfeng/atuin"
      tag = "16"
    }
    atuin_db = {
      uri = "docker.io/library/postgres"
      tag = "18.10.0"
    }
    ddclient = {
      uri = "ghcr.io/linuxserver/ddclient"
      tag = "latest"
    }
    gitsave = {
      uri = "docker.io/library/alpine"
      tag = "latest"
    }
    gluetun = {
      uri = "docker.io/qmcgaw/gluetun"
      tag = "latest"
    }
    healthchecks = {
      uri = "docker.io/linuxserver/healthchecks"
      tag = "12"
    }
    homeassistant = {
      uri = "ghcr.io/home-assistant/home-assistant"
      tag = "2025.2.5"
    }
    immich_server = {
      uri = "ghcr.io/immich-app/immich-server"
      tag = "v2.2.0"
    }
    immich_ml = {
      uri = "ghcr.io/immich-app/immich-machine-learning"
      tag = "v2.2.0"
    }
    immich_postgres = {
      uri = "tensorchord/pgvecto-rs"
      tag = "pg14-v0.3.0"
    }
    kimai = {
      uri = "docker.io/kimai/kimai-apache"
      tag = "12"
    }
    kimai_db = {
      uri = "docker.io/library/postgres"
      tag = "apache"
    }
    koillection = {
      uri = "docker.io/koillection/koillection"
      tag = "1.7.0"
    }
    koillection_postgres = {
      uri = "docker.io/library/postgres"
      tag = "16"
    }
    kopia = {
      uri = "docker.io/kopia/kopia"
      tag = "latest"
    }
    mariadb = {
      uri = "docker.io/library/mariadb"
      tag = "12"
    }
    mosquitto = {
      uri = "docker.io/eclipse-mosquitto"
      tag = "2"
    }
    nextcloud = {
      uri = "docker.io/library/nextcloud"
      tag = "12"
    }
    paperless_ngx = {
      uri = "docker.io/paperlessngx/paperless-ngx"
      tag = "latest"
    }
    postgres = {
      uri = "docker.io/library/postgres"
      tag = "16"
    }
    prowlarr = {
      uri = "docker.io/linuxserver/prowlarr"
      tag = "latest"
    }
    qbittorrent = {
      uri = "docker.io/linuxserver/qbittorrent"
      tag = "latest"
    }
    radarr = {
      uri = "docker.io/linuxserver/radarr"
      tag = "latest"
    }
    radicale = {
      uri = "docker.io/radicale/radicale"
      tag = "3.1.9"
    }
    smokeping = {
      uri = "docker.io/linuxserver/smokeping"
      tag = "latest"
    }
    sonarr = {
      uri = "docker.io/linuxserver/sonarr"
      tag = "latest"
    }
    tautulli = {
      uri = "docker.io/linuxserver/tautulli"
      tag = "latest"
    }
    vaultwarden = {
      uri = "docker.io/vaultwarden/server"
      tag = "latest"
    }
    webtrees = {
      uri = "docker.io/linuxserver/webtrees"
      tag = "12"
    }
    webtrees_db = {
      uri = "docker.io/library/mysql"
      tag = "latest"
    }
    z2m = {
      uri = "docker.io/zigbee2mqtt/zigbee2mqtt"
      tag = "latest"
    }
  }
}
