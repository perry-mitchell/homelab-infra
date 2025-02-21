module "dashboard" {
    source = "../../modules/k8s-dashboard"

    depends_on = [ module.k3s_auth ]

    dns_config = {
        cluster_fqdn = var.cluster_fqdn
        host_ip = local.primary_ingress_ip
        subdomain_name = "k8s"
    }
    tailscale = {
        hostname = "k8s"
        host_ip = local.primary_ingress_ip
        tailnet = var.tailscale_tailnet
    }
}
