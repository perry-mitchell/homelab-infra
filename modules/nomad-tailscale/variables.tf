variable "datacenter" {
    type = string
}

variable "name" {
    type = string
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

variable "tailscale_auth_key" {
    type = string
}

variable "tailscale_hostname" {
    type = string
}

variable "tailscale_routes" {
    type = string
}
