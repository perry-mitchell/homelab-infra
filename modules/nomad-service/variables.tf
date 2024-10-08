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
    })
}

variable "volumes" {
    default = {}
    type = map(object({
        container_directory = string
    }))
}
