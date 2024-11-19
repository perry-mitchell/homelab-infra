variable "cluster_db_root_password" {
    sensitive = true
    type = string
}

variable "cluster_init_node" {
    type = string
}

variable "cluster_token" {
    sensitive = true
    type = string
}

variable "nodes" {
    sensitive = true
    type = set(object({
        is_master = bool
        name = string
        ip = string
        user = string
        password = string
    }))
}

variable "state_encryption_passphrase" {
    sensitive = true
    type = string
}
