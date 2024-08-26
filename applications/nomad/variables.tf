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

variable "state_encryption_passphrase" {
    type = string
}
