variable "k3s_database_password" {
    type = string
}

variable "k3s_database_root_password" {
    type = string
}

variable "k3s_database_username" {
    type = string
}

variable "k3s_database_server" {
    type = object({
        ip = string
        password = string
        user = string
        work_dir = string
    })
}

variable "k3s_servers" {
    type = map(object({
        ip = string
        password = string
        user = string
        work_dir = string
    }))
}
