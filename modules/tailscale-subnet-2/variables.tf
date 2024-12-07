variable "additional_cidrs" {
    default = []
    type = set(string)
}

variable "auth_key" {
    type = string
}

variable "storage" {
    description = "The storage name"
    type = string
}
