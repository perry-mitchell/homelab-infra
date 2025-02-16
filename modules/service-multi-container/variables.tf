variable "containers" {
    type = map(object({
        args = optional(list(string), null)
        capabilities = optional(set(string), null)
        command = optional(list(string), null)
        container_port = optional(number, null)
        environment = optional(map(string), {})
        image = object({
            tag = string
            uri = string
        })
        init = optional(bool, false)
        nfs_mounts = optional(map(object({
            create_subdir = bool
            container_path = string
            nfs_export = string
            nfs_server = string
            read_only = optional(bool, false)
            storage_request = optional(string, "50Gi")
        })), {})
        restart_policy = optional(string, null)
        run_as = optional(object({
            user = number
            group = number
        }), null)
        service_port = optional(number, null)
    }))
}

variable "dns_config" {
    type = object({
        cluster_fqdn = string
        host_ip = string
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
    type = string
}

variable "namespace" {
    type = string
}

variable "tailscale" {
    type = object({
        host_ip = string
        tailnet = string
    })
}
