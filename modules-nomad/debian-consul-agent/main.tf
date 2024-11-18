module "consul_provisioning" {
    source = "../debian-puppet"

    puppet_file = "${path.module}/consul.pp"
    server_ip = var.server_ip
    server_password = var.server_password
    server_user = var.server_user
    vars = {
        client_hcl = templatefile("${path.module}/client.hcl.tftpl", {
            consul_agent_ip = var.server_ip,
            client_name = var.node_name,
            consul_server = var.consul_master_ip,
            gossip_key = var.consul_encryption_key
        })
        consul_service = templatefile("${path.module}/consul.service.tftpl", {})
    }
    work_directory = var.work_directory
}
