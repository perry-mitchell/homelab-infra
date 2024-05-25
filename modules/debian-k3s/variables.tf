variable "agent_token" {
    type = string
}

variable "cluster_token" {
    type = string
}

variable "database_uri" {
    type = string
}

variable "node_labels" {
    default = {}
    type = map(string)
}

variable "server_ip" {
    type = string
}

variable "server_node" {
    type = bool
}

variable "server_password" {
    type = string
}

variable "server_user" {
    type = string
}

variable "work_directory" {
    type = string
}
