variable "create_database" {
  default  = null
  nullable = true
  type     = string
}

variable "create_user" {
  default  = null
  nullable = true
  type = object({
    password = string
    username = string
  })
}

variable "db_host" {
  type = string
}

variable "db_password" {
  sensitive = true
  type      = string
}

variable "db_username" {
  type = string
}

variable "grant_users" {
  description = "Grant user (key) all-access on database (value)"
  default     = {}
  type        = map(string)
}

variable "name" {
  type = string
}

variable "namespace" {
  default = "default"
  type    = string
}
