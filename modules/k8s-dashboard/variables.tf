variable "dns_config" {
    type = object({
      cluster_fqdn = string
      host_ip = string
      subdomain_name = string
    })
}

variable "tailscale" {
    default = null
    type = object({
        hostname = string
        host_ip = string
        tailnet = string
    })
}
