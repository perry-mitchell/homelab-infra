variable "create_database" {
  type = string
}

variable "create_user" {
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

variable "extra_sql_lines" {
  default = []
  type    = list(string)
}

variable "name" {
  type = string
}

variable "namespace" {
  default = "default"
  type    = string
}
