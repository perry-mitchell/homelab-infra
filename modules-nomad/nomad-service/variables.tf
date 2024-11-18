variable "datacenter" {
    type = string
}

variable "docker_cap_add" {
    default = []
    type = set(string)
}

variable "docker_hostname" {
    default = null
    type = string
}

variable "docker_network_mode" {
    default = null
    type = string
}

variable "docker_privileged" {
    default = false
    type = bool
}

variable "docker_volumes" {
    default = []
    type = set(string)
}

variable "environment" {
    default = {}
    type = map(string)
}

variable "image" {
    type = string
}

variable "mounts" {
    default = []
    type = list(object({
        # filename = string
        directory = string
        files = list(object({
            contents = string
            filename = string
        }))
        # contents = string
    }))
}

variable "name" {
    type = string
}

variable "ports" {
    default = {}
    type = map(string)
}

variable "resources" {
    type = object({
        cpu = number
        memory = number
    })
}

variable "storage" {
    default = null
    type = object({
        mount = string
        name = string
        server = string
        server_chown = string
        server_password = string
        server_user = string
    })
}

variable "volumes" {
    default = []
    type = set(object({
        container_directory = string
        mount_name = string
    }))
}
