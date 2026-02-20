variable "cluster_name" {
  type = string
}

variable "containers" {
  type = map(object({
    args         = optional(list(string), null)
    capabilities = optional(set(string), null)
    command      = optional(list(string), null)
    environment  = optional(map(string), {})
    fs_group     = optional(number, null)
    image = object({
      tag = string
      uri = string
    })
    longhorn_mounts = optional(map(object({
      container_path  = string
      storage_request = string
    })), {})
    nfs_mounts = optional(map(object({
      create_subdir   = bool
      container_path  = string
      nfs_export      = string
      nfs_server      = string
      read_only       = optional(bool, false)
      storage_request = optional(string, "50Gi")
    })), {})
    ports = optional(list(object({
       container = number
       internal_hostname = optional(string, null)
       public_access = optional(object({
         cluster_ip = optional(string, null)
         hostname = string
         ingress_class = optional(string, null)
       }), null)
       service   = number
       tailscale_hostname = optional(string, null)
     })), [])
    restart_policy = optional(string, null)
    run_as = optional(object({
      user  = number
      group = number
    }), null)
    static_mounts = optional(map(string), {})
  }))
}

variable "longhorn_storage_class" {
  type = string
}

variable "name" {
  type = string
}

variable "namespace" {
  type = string
}

variable "replicas" {
  type    = number
  default = 1
}

variable "public_ingress_class" {
  type    = string
  default = "nginx-public"
}
