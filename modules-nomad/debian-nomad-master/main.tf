module "nomad_provisioning" {
    source = "../debian-puppet"

    puppet_file = "${path.module}/nomad.pp"
    server_ip = var.server_ip
    server_password = var.server_password
    server_user = var.server_user
    vars = {
        nomad_hcl = templatefile("${path.module}/nomad.hcl.tftpl", {
            consul_master_ip = var.consul_master_ip,
            gossip_key = var.consul_encryption_key
        })
        nomad_service = templatefile("${path.module}/nomad.service.tftpl", {})
    }
    work_directory = var.work_directory
}
