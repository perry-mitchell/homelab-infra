variable "containers" {
    type = map(object({
        capabilities = optional(set(string), null)
        container_port = number
        environment = optional(map(string), {})
        image = object({
            tag = string
            uri = string
        })
        nfs_mounts = optional(map(object({
            create_subdir = bool
            container_path = string
            nfs_export = string
            nfs_server = string
            read_only = optional(bool, false)
            storage_request = optional(string, "50Gi")
        })), {})
        run_as = optional(object({
            user = number
            group = number
        }), null)
        service_port = number
    }))
}

variable "name" {
    type = string
}

variable "namespace" {
    type = string
}
