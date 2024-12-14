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

variable "network_cidrs" {
    type = set(string)
}

variable "nfs_storage" {
    type = map(object({
        export = string
        host = string
        path_pattern = string
    }))
}

variable "nodes" {
    type = set(object({
        is_master = bool
        name = string
        ip = string
        user = string
        password = string
    }))
}

variable "pihole_password" {
    type = string
}

variable "pihole_url" {
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
