locals {
    master_config_filename = var.cluster_init ? "config.master-init.yaml.tftpl" : "config.master-join.yaml.tftpl"
    work_directory = "/tmp/tf-k3s-${formatdate("YYYYMMDD", "2025-02-19T18:54:00+02:00")}"
}

module "master_provisioning" {
    source = "../debian-puppet"
    count = var.is_master ? 1 : 0

    puppet_file = "${path.module}/k3s.pp"
    server_ip = var.server_ip
    server_password = var.server_password
    server_user = var.server_user
    vars = {
        config_yaml = templatefile("${path.module}/${local.master_config_filename}", {
            cluster_token = var.cluster_token
            fqdn = var.fqdn
            main_server_ip = var.main_server_ip
            node_name = var.node_name
            server_ip = var.server_ip
        })
        k3s_service = templatefile("${path.module}/k3s.service.tftpl", {
            k3s_exec_start = "/usr/local/bin/k3s server"
        })
        node_hostname = var.hostname
    }
    work_directory = local.work_directory
}

module "worker_provisioning" {
    source = "../debian-puppet"
    count = var.is_master ? 0 : 1

    puppet_file = "${path.module}/k3s.pp"
    server_ip = var.server_ip
    server_password = var.server_password
    server_user = var.server_user
    vars = {
        config_yaml = templatefile("${path.module}/config.worker.yaml.tftpl", {
            cluster_token = var.cluster_token
            main_server_ip = var.main_server_ip
            node_name = var.node_name
        })
        k3s_service = templatefile("${path.module}/k3s.service.tftpl", {
            k3s_exec_start = "/usr/local/bin/k3s agent"
        })
        node_hostname = var.hostname
    }
    work_directory = local.work_directory
}
