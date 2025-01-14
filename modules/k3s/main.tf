locals {
    config_filename = var.cluster_init ? "config.master-init.yaml.tftpl" : "config.master-join.yaml.tftpl"
    work_directory = "/tmp/tf-k3s-${formatdate("YYYYMMDD", "2024-11-24T21:07:45+02:00")}"
}

module "nomad_provisioning" {
    source = "../debian-puppet"

    puppet_file = "${path.module}/k3s.pp"
    server_ip = var.server_ip
    server_password = var.server_password
    server_user = var.server_user
    vars = {
        config_yaml = templatefile("${path.module}/${local.config_filename}", {
            cluster_token = var.cluster_token
            fqdn = var.fqdn
            main_server_ip = var.main_server_ip
            node_name = var.node_name
            server_ip = var.server_ip
        })
        node_hostname = var.hostname
        k3s_service = file("${path.module}/k3s.service")
    }
    work_directory = local.work_directory
}
