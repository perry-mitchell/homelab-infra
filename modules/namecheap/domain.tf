# resource "cloudflare_zone" "homelab_domain" {
#     zone = var.tunnel_domain
#     account_id = var.cloudflare_account_id
# }

# resource "namecheap_domain_records" "homelab_domain" {
#     domain = var.tunnel_domain
#     mode = "OVERWRITE"

#     nameservers = cloudflare_zone.homelab_domain.name_servers
# }
