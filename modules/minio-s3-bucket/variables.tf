variable "bucket" {
    type = string
}

variable "minio_auth" {
    type = object({
        password = string
        server = string
        username = string
    })
}
