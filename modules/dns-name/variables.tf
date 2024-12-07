variable "cluster_fqdn" {
    type = string
}

variable "host_ip" {
    type = string
}

variable "subdomain_name" {
    description = "The subdomain name prefix. Eg. test.site.local, where site.local is the FQDN, would have this value set to 'test'."
    type = string
}
