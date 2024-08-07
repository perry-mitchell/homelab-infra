variable "k3s_agent_token" {
    type = string
}

variable "k3s_cluster_token" {
    type = string
}

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
        labels = map(string)
        password = string
        server = bool
        user = string
        work_dir = string
    }))
}
