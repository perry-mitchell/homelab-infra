module "consul_master" {
    source = "../../modules/debian-consul-master"

    consul_encryption_key = var.consul_encryption_key

    server_ip = var.consul_master.ip
    server_password = var.consul_master.password
    server_user = var.consul_master.user
    work_directory = var.consul_master.work_dir
}

module "nomad_master" {
    source = "../../modules/debian-nomad-master"

    depends_on = [ module.consul_master ]

    consul_encryption_key =var.consul_encryption_key
    consul_master_ip = var.consul_master.ip
    server_ip = var.nomad_master.ip
    server_password = var.nomad_master.password
    server_user = var.nomad_master.user
    work_directory = var.nomad_master.work_dir
}

module "nomad_worker" {
    source = "../../modules/debian-nomad-worker"

    for_each = {
      for index, worker in var.nomad_workers: worker.name => worker
    }

    depends_on = [ module.nomad_master ]

    # consul_master_ip = var.consul_master.ip
    nomad_master_ip = var.nomad_master.ip
    server_ip = each.value.ip
    server_password = each.value.password
    server_user = each.value.user
    work_directory = each.value.work_dir
}

module "nomad_worker_consul_agent" {
    source = "../../modules/debian-consul-agent"

    for_each = {
      for index, worker in var.nomad_workers: worker.name => worker
    }

    depends_on = [ module.nomad_worker ]

    consul_encryption_key = var.consul_encryption_key
    consul_master_ip = var.consul_master.ip
    node_name = each.value.name
    server_ip = each.value.ip
    server_password = each.value.password
    server_user = each.value.user
    work_directory = each.value.work_dir
}
