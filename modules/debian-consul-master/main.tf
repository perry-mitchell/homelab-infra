module "consul_provisioning" {
    source = "../debian-puppet"

    puppet_file = "${path.module}/consul.pp"
    server_ip = var.server_ip
    server_password = var.server_password
    server_user = var.server_user
    work_directory = var.work_directory
}
