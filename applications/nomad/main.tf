module "consul_master" {
    source = "../../modules/debian-consul-master"

    consul_encryption_key = var.consul_encryption_key

    server_ip = var.consul_master.ip
    server_password = var.consul_master.password
    server_user = var.consul_master.user
    work_directory = var.consul_master.work_dir
}
