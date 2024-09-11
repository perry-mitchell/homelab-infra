variable "datacenter" {
    type = string
}

variable "environment" {
    default = {}
    type = map(string)
}

variable "image" {
    type = string
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
    type = object({
        mount = string
        name = string
        server = string
    })
}

variable "volumes" {
    default = []
    type = list(object({
        container_directory = string
        remote_directory = string
    }))
}
