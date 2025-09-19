variable "longhorn_storage_class" {
    type = string
    default = "harvester-longhorn"
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

variable "state_encryption_passphrase" {
    type = string
}

variable "tailscale_container_auth" {
    type = string
}
