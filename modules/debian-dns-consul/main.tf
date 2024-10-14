module "consul_dns_provisioning" {
    source = "../debian-puppet"

    puppet_file = "${path.module}/dns.pp"
    server_ip = var.server_ip
    server_password = var.server_password
    server_user = var.server_user
    vars = {
        dns_server = var.dns_server
        # consul_hcl = templatefile("${path.module}/consul.hcl.tftpl", {
        #     gossip_key = var.consul_encryption_key
        # })
    }
    work_directory = var.work_directory
}
