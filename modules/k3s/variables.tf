variable "cluster_init" {
  default = false
  type    = bool
}

variable "cluster_token" {
  type = string
}

variable "fqdn" {
  default  = null
  nullable = true
  type     = string
}

variable "hostname" {
  type = string
}

variable "is_master" {
  type = bool
}

variable "main_server_ip" {
  type = string
}

variable "node_name" {
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
