variable "container_port" {
    type = number
}

variable "dns_config" {
    type = object({
      cluster_fqdn = string
      host_ip = string
      subdomain_name = string
    })
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
