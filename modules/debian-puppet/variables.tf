variable "puppet_file" {
    type = string
}

variable "server_ip" {
    type = string
}

variable "server_password" {
    type = string
}

variable "server_user" {
    type = string
}

variable "vars" {
    default = {}
    type = map(string)
}

variable "work_directory" {
    type = string
}
