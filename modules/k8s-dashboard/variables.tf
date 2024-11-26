variable "dns_config" {
    type = object({
      cluster_fqdn = string
      host_ip = string
      subdomain_name = string
    })
}
