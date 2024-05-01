module "k3s_provisioning" {
    source = "../debian-puppet"

    puppet_file = "${path.module}/provision.pp"
    server_ip = var.server_ip
    server_password = var.server_password
    server_user = var.server_user
    work_directory = var.work_directory
}
