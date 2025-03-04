variable "args" {
    default = null
    nullable = true
    type = list(string)
}

variable "command" {
    default = null
    nullable = true
    type = list(string)
}

variable "container_port" {
    default = null
    nullable = true
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

variable "nfs_mounts" {
    default = {}
    type = map(object({
        create_subdir = bool
        container_path = string
        nfs_export = string
        nfs_server = string
        read_only = optional(bool, false)
        storage_request = optional(string, "50Gi")
    }))
}

variable "privileged" {
    type = bool
    default = false
}

variable "read_only_root_filesystem" {
    type = bool
    default = false
}

variable "replicas" {
    default = 1
    type = number
}

variable "run_as" {
    default = null
    nullable = true
    type = object({
        user = number
        group = number
    })
}

variable "samba_mounts" {
    default = {}
    type = map(object({
        container_path = string
        create_subdir = bool
        gid = optional(number, null)
        password = string
        read_only = optional(bool, false)
        server = string
        share = string
        storage_request = optional(string, "50Gi")
        uid = optional(number, null)
        username = string
    }))
}

variable "service_port" {
    default = null
    nullable = true
    type = number
}

variable "share_process_namespace" {
    default = false
    type = bool
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

variable "tailscale_port_alternatives" {
    default = {}
    type = map(object({
        hostname = string
        port = number
    }))
}
