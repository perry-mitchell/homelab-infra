locals {
  work_directory = "/tmp/tf-k3s-${formatdate("YYYYMMDD", timestamp())}"
}

module "nomad_provisioning" {
    source = "../debian-puppet"

    puppet_file = "${path.module}/k3s.pp"
    server_ip = var.server_ip
    server_password = var.server_password
    server_user = var.server_user
    vars = {
        config_yaml = templatefile("${path.module}/config.yaml.tftpl", {
            cluster_token = var.cluster_token
            is_cluster_init = var.cluster_init
            node_name = var.node_name
            server_ip = var.server_ip
        })
        k3s_service = file("${path.module}/k3s.service")
        # nomad_hcl = templatefile("${path.module}/nomad.hcl.tftpl", {
        #     nomad_server_ip = var.nomad_master_ip
        #     nomad_worker_ip = var.server_ip
        # })
        # nomad_service = templatefile("${path.module}/nomad.service.tftpl", {})
    }
    work_directory = local.work_directory
}
