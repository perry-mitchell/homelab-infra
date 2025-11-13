variable "cluster_name" {
  default = "torrens"
  type    = string
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

variable "db_redis_root" {
  type = string
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
}

variable "longhorn_storage_class" {
  type    = string
  default = "harvester-longhorn"
}

variable "network_cidrs" {
  type = set(string)
}

variable "nfs_storage" {
  type = map(object({
    export       = string
    host         = string
    path_pattern = string
  }))
}

variable "radicale_users" {
  type = map(string)
}

variable "state_encryption_passphrase" {
  type = string
}

variable "tailscale_container_auth" {
  type = string
}

variable "tailscale_oauth" {
  type = object({
    client_id     = string
    client_secret = string
  })
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
}

variable "webtrees_admin" {
  type = object({
    email    = string
    name     = string
    password = string
    username = string
  })
}
