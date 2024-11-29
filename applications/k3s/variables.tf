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

variable "nfs_storage_primary" {
    type = object({
        export = string
        host = string
    })
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
