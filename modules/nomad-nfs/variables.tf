variable "datacenter" {
    type = string
}

variable "storage" {
    type = object({
        mount = string
        name = string
        server = string
    })
}
