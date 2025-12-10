variable "additional_cidrs" {
  default = []
  type    = set(string)
}

variable "auth_key" {
  type = string
}

variable "hostname" {
  type = string
}

variable "longhorn_mounts" {
  default = {}
  type = map(object({
    container_path  = string
    storage_request = string
  }))
}

variable "longhorn_storage_class" {
  type = string
}

variable "namespace" {
  type = string
}

variable "replicas" {
  default = 1
  type = number
}
