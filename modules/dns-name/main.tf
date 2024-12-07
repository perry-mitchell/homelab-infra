resource "pihole_dns_record" "record" {
    domain = join(".", [var.subdomain_name, var.cluster_fqdn])
    ip = var.host_ip
}
