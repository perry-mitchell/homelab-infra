variable "additional_cidrs" {
    default = []
    type = set(string)
}

variable "auth_key" {
    type = string
}

variable "longhorn_mounts" {
    default = {}
    type = map(object({
        container_path = string
        storage_request = string
    }))
}

variable "namespace" {
    type = string
}
