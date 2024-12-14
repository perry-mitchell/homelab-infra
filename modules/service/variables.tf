variable "command" {
    default = null
    nullable = true
    type = list(string)
}

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

variable "ingress_upload_size" {
    default = "50m"
    type = string

    validation {
        condition = can(regex("^[0-9]+(k|m|g|K|M|G)?$", var.ingress_upload_size))
        error_message = "The ingress_upload_size value must be a valid size expression (e.g., 50m, 1G, 500k)."
    }
}

variable "name" {
    description = "Application name, k8s friendly"
    type = string
}

variable "namespace" {
    type = string
}

variable "root_mounts" {
    default = {}
    type = map(object({
        container_path = string
        nfs_export = string
        nfs_server = string
        read_only = bool
        storage_name = string
        storage_request = optional(string)
    }))
}

variable "service_port" {
    type = number
}

variable "subdir_mounts" {
    default = {}
    type = map(object({
        container_path = string
        storage = string
        storage_request = optional(string)
    }))
}

variable "tailscale" {
    default = null
    type = object({
      hostname = string
      host_ip = string
      tailnet = string
    })
}
