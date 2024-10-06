variable "consul_encryption_key" {
    type = string
}

variable "consul_master" {
    type = object({
        ip = string
        password = string
        user = string
        work_dir = string
    })
}

variable "datacenter" {
    type = string
    default = "nak4"
}

variable "db_mariadb_root" {
    type = string
}

variable "nomad_master" {
    type = object({
        ip = string
        password = string
        user = string
        work_dir = string
    })
}

variable "nomad_workers" {
    type = list(object({
        name = string
        ip = string
        password = string
        user = string
        work_dir = string
    }))
}

variable "state_encryption_passphrase" {
    type = string
}

variable "storage_backends" {
    type = object({
      alpha = object({
        mount = string
        server = string
      })
    })
}

variable "tailscale_container_auth" {
    type = string
}
