variable "adventurelog_django_admin" {
  type = object({
    email = string
    password = string
    username = string
  })
}

variable "cluster_name" {
  default = "torrens"
  type    = string
}

variable "drone_ci" {
  type = object({
    github_client_id     = string
    github_client_secret = string
    rpc_secret           = string
    admin_user           = string
  })
  sensitive = true
}

variable "db_mariadb_root" {
  type = string
  sensitive = true
}

variable "db_postgres_root" {
  type = string
  sensitive = true
}

variable "db_postgres_pgvecto_rs_root" {
  type = string
  sensitive = true
}

variable "db_redis_root" {
  type = string
  sensitive = true
}

variable "gitsave" {
  type = object({
    encryption_secret = string
    jwt = string
  })
}

variable "healthchecks_email" {
  type = object({
    from = string
    host = string
    password = string
    port = number
    tls = bool
    user = string
  })
}

variable "kimai_admin" {
  type = object({
    email    = string
    password = string
  })
  sensitive = true
}

variable "kopia_admin" {
  type = object({
    password = string
    username = string
  })
  sensitive = true
}

variable "letsencrypt_email" {
  description = "Email for Let's Encrypt certificate notifications"
  type        = string
}

variable "longhorn_storage_class" {
  type    = string
  default = "harvester-longhorn"
}

variable "network_cidrs" {
  type = set(string)
}

variable "nextcloud_auth" {
  type = object({
    username = string
    password = string
  })
  sensitive = true
}

variable "nfs_storage" {
  type = map(object({
    export       = string
    host         = string
    path_pattern = string
  }))
}

variable "paperless_auth" {
  type = object({
    admin_mail     = string
    admin_password = string
    admin_user     = string
  })
  sensitive = true
}

variable "public_domain" {
  type = string
}

variable "radicale_users" {
  type = map(string)
}

variable "state_encryption_passphrase" {
  type = string
  sensitive = true
}

variable "tailscale_container_auth" {
  type = string
  sensitive = true
}

variable "tailscale_oauth" {
  type = object({
    client_id     = string
    client_secret = string
  })
  sensitive = true
}

variable "tailscale_tailnet" {
  type = string
}

variable "vpn_provider" {
  type = object({
    endpoint_ip      = string
    endpoint_port    = number
    inbound_ports    = list(number)
    provider         = string
    server_hostnames = list(string)
    username         = string
    password         = string
  })
  sensitive = true
}

variable "webtrees_admin" {
  type = object({
    email    = string
    name     = string
    password = string
    username = string
  })
  sensitive = true
}
