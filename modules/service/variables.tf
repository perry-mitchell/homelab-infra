variable "command" {
    default = null
    nullable = true
    type = list(string)
}

variable "container_port" {
    type = number
}

variable "capabilities" {
    default = null
    type = set(string)
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

variable "host_network" {
    default = false
    type = bool
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

variable "longhorn_mounts" {
    default = {}
    type = map(object({
        container_path = string
        storage_request = string
    }))
}

variable "name" {
    description = "Application name, k8s friendly"
    type = string
}

variable "namespace" {
    type = string
}

variable "replicas" {
    default = 1
    type = number
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

variable "run_as" {
    default = null
    nullable = true
    type = object({
        user = number
        group = number
    })
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
        funnel = optional(bool, false)
        hostname = string
        host_ip = string
        tailnet = string
    })
}
