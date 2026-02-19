locals {
  # Container image definitions (uri + tag)
  images = {
    adventurelog = {
      uri = "ghcr.io/adventurelog/adventurelog"
      tag = "latest"
    }
    adventurelog_backend = {
      uri = "ghcr.io/seanmorley15/adventurelog-backend"
      tag = "latest"
    }
    adventurelog_frontend = {
      uri = "ghcr.io/seanmorley15/adventurelog-frontend"
      tag = "latest"
    }
   adventurelog_postgis = {
      uri = "postgis/postgis"
      tag = "16-3.5"
    }
    atuin = {
      uri = "ghcr.io/atuinsh/atuin"
      tag = "18.10.0"
    }
    atuin_db = {
      uri = "postgres"
      tag = "16"
    }
    ddclient = {
      uri = "lscr.io/linuxserver/ddclient"
      tag = "latest"
    }
    faster_whisper = {
      uri = "lscr.io/linuxserver/faster-whisper"
      tag = "latest"
    }
    gitsave = {
      uri = "timwitzdam/gitsave"
      tag = "latest"
    }
    gluetun = {
      uri = "qmcgaw/gluetun"
      tag = "latest"
    }
    healthchecks = {
      uri = "healthchecks/healthchecks"
      tag = "latest"
    }
    healthchecks_db = {
      uri = "mariadb"
      tag = "12"
    }
    homeassistant = {
      uri = "lscr.io/linuxserver/homeassistant"
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
      uri = "kimai/kimai2"
      tag = "apache"
    }
    kimai_db = {
      uri = "mariadb"
      tag = "12"
    }
    koillection = {
      uri = "koillection/koillection"
      tag = "1.7.0"
    }
    koillection_postgres = {
      uri = "postgres"
      tag = "16"
    }
    kopia = {
      uri = "ghcr.io/imagegenius/kopia"
      tag = "latest"
    }
    mariadb = {
      uri = "mariadb"
      tag = "12"
    }
    mealie = {
      uri = "hkotel/mealie"
      tag = "latest"
    }
    mealie_db = {
      uri = "postgres"
      tag = "16"
    }
    mosquitto = {
      uri = "eclipse-mosquitto"
      tag = "2"
    }
    nextcloud_db = {
      uri = "mariadb"
      tag = "12"
    }
    overseerr = {
      uri = "lscr.io/linuxserver/overseerr"
      tag = "latest"
    }
    paperless_ngx = {
      uri = "paperlessngx/paperless-ngx"
      tag = "latest"
    }
    paperless_db = {
      uri = "mariadb"
      tag = "12"
    }
    piper = {
      uri = "lscr.io/linuxserver/piper"
      tag = "latest"
    }
    postgres = {
      uri = "postgres"
      tag = "16"
    }
    redis = {
      uri = "bitnami/redis"
      tag = "latest"
    }
    prowlarr = {
      uri = "lscr.io/linuxserver/prowlarr"
      tag = "latest"
    }
    qbittorrent = {
      uri = "lscr.io/linuxserver/qbittorrent"
      tag = "latest"
    }
    radarr = {
      uri = "lscr.io/linuxserver/radarr"
      tag = "latest"
    }
    radicale = {
      uri = "11notes/radicale"
      tag = "3.1.9"
    }
    smokeping = {
      uri = "lscr.io/linuxserver/smokeping"
      tag = "latest"
    }
    sonarr = {
      uri = "lscr.io/linuxserver/sonarr"
      tag = "latest"
    }
    tautulli = {
      uri = "lscr.io/linuxserver/tautulli"
      tag = "latest"
    }
    vaultwarden = {
      uri = "vaultwarden/server"
      tag = "latest"
    }
    webtrees = {
      uri = "nathanvaughn/webtrees"
      tag = "latest"
    }
    webtrees_db = {
      uri = "mariadb"
      tag = "12"
    }
    z2m = {
      uri = "koenkk/zigbee2mqtt"
      tag = "latest"
    }
  }
}
