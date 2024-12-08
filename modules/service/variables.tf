variable "container_port" {
    type = number
}

variable "dns_config" {
    default = null
    nullable = true
    type = object({
      cluster_fqdn = string
      host_ip = string
      subdomain_name = string
    })
}

variable "environment" {
    default = {}
    type = map(string)
}

variable "files" {
    default = {}
    type = map(string)
}

variable "image" {
    type = object({
        tag = string
        uri = string
    })
}

variable "mounts" {
    default = {}
    type = map(object({
        container_path = string
        storage = string
        storage_request = optional(string)
    }))
}

variable "name" {
    description = "Application name, k8s friendly"
    type = string
}

variable "namespace" {
    type = string
}

variable "service_port" {
    type = number
}

variable "tailscale" {
    default = null
    type = object({
      hostname = string
      host_ip = string
      tailnet = string
    })
}
