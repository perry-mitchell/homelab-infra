module "consul_provisioning" {
    source = "../debian-puppet"

    puppet_file = "${path.module}/consul.pp"
    server_ip = var.server_ip
    server_password = var.server_password
    server_user = var.server_user
    vars = {
        consul_hcl = templatefile("${path.module}/consul.hcl.tftpl", {
            gossip_key = var.consul_encryption_key
        })
        consul_service = templatefile("${path.module}/consul.service.tftpl", {})
        ten_consul = templatefile("${path.module}/10-consul.tftpl", {})
    }
    work_directory = var.work_directory
}
