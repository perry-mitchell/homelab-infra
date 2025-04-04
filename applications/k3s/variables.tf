variable "admin_email" {
  type = string
}

variable "backblaze_auth" {
    type = object({
      application_key = string
      application_key_id = string
    })
}

variable "backblaze_bucket_prefix" {
    type = string
}

variable "cloudflare_auth" {
    type = object({
        account_id = string
        api_token = string
    })
}

variable "cluster_db_root_password" {
    type = string
}

variable "cluster_fqdn" {
    type = string
}

variable "cluster_init_node" {
    type = string
}

variable "cluster_token" {
    type = string
}

variable "code_auth" {
    type = object({
        sudo_password = string
    })
}

variable "db_mariadb_root" {
    type = string
}

variable "db_postgres_root" {
    type = string
}

variable "db_postgres_pgvecto_rs_root" {
    type = string
}

variable "db_postgres_postgis_root" {
    type = string
}

variable "db_redis_root" {
    type = string
}

variable "gitsave_jwt" {
    type = string
}

variable "homeassistant_api_key" {
    type = string
}

variable "homebox_auth" {
    type = object({
        username = string
        password = string
    })
}

variable "immich_api_keys" {
    type = object({
        homepage = string
    })
}

variable "kimai_admin" {
    type = object({
        email = string
        password = string
    })
}

variable "kopia_admin" {
    type = object({
        password = string
        username = string
    })
}

variable "namecheap_auth" {
    type = object({
        api_key = string
        api_user = string
        client_ip = optional(string)
        username = string
    })
}

variable "network_cidrs" {
    type = set(string)
}

variable "nextcloud_auth" {
    type = object({
        username = string
        password = string
    })
}

variable "nfs_storage" {
    type = map(object({
        export = string
        host = string
        path_pattern = string
    }))
}

variable "nfs_storage_backup" {
    type = map(object({
        export = string
        host = string
    }))
}

variable "nodes" {
    type = set(object({
        description = string
        ip = string
        is_master = bool
        labels = optional(map(string))
        name = string
        password = string
        user = string
    }))
}

variable "overseerr_token" {
    type = string
}

variable "paperless_auth" {
    type = object({
        admin_mail = string
        admin_password = string
        admin_user = string
    })
}

variable "pihole_admin_url" {
    type = string
}

variable "pihole_api_key" {
    type = string
}

variable "pihole_password" {
    type = string
}

variable "pihole_url" {
    type = string
}

variable "plex_token" {
    type = string
}

variable "plex_url_base" {
    type = string
}

variable "prowlarr_token" {
    type = string
}

variable "radarr_token" {
    type = string
}

variable "samba_storage" {
    type = map(object({
        password = string
        server = string
        share = string
        username = string
    }))
}

variable "sonarr_token" {
    type = string
}

variable "state_encryption_passphrase" {
    type = string
}

variable "tailscale_container_auth" {
    type = string
}

variable "tailscale_oauth" {
    type = object({
      client_id = string
      client_secret = string
    })
}

variable "tailscale_tailnet" {
    type = string
}

variable "tautulli_api_key" {
    type = string
}

variable "tunnel_domain" {
    description = "Public-facing tunnelled domain"
    type = string
}

variable "unifi_auth" {
    type = object({
        password = string
        username = string
    })
}

variable "unifi_url" {
    type = string
}

variable "vpn_provider" {
    type = object({
        endpoint_ip = string
        endpoint_port = number
        inbound_ports = list(number)
        provider = string
        server_hostnames = list(string)
        username = string
        password = string
    })
}

variable "wdosg_auth" {
    type = object({
        encryption_key = string
        twitch_app_access_token = string
        twitch_client_id = string
    })
}

variable "webtrees_admin" {
    type = object({
        email = string
        name = string
        password = string
        username = string
    })
}
