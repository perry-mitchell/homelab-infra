#region Provisioning
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

    nomad_master_ip = var.nomad_master.ip
    server_ip = each.value.ip
    server_password = each.value.password
    server_user = each.value.user
    work_directory = "${each.value.work_dir}/nomad"
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
    work_directory = "${each.value.work_dir}/consul"
}
#endregion

locals {
    storage_config = {
        mount = var.storage_backends.alpha.mount
        name = "alpha"
        server = var.storage_backends.alpha.server
    }
}

#region Storage
module "nomad_nfs" {
    source = "../../modules/nomad-nfs"

    depends_on = [module.nomad_master, module.nomad_worker]

    datacenter = var.datacenter
    storage = local.storage_config
}
#endregion

#region Apps
module "app_smokeping" {
    source = "../../modules/nomad-service"

    depends_on = [ module.nomad_nfs ]
    datacenter = var.datacenter
    image = "lscr.io/linuxserver/smokeping:latest"
    name = "smokeping"
    ports = {
        "35000" = "80"
    }
    resources = {
        cpu = 250
        memory = 250
    }
    storage = local.storage_config
    volumes = [
        {
            container_directory = "/config"
            remote_directory = "config"
        },
        {
            container_directory = "/data"
            remote_directory = "data"
        }
    ]
}

module "app_demo" {
    source = "../../modules/nomad-service"

    depends_on = [ module.nomad_nfs ]
    datacenter = var.datacenter
    image = "shelleg/demo-nodejs-http-server:latest"
    name = "demo"
    ports = {
        "35001" = "8080"
    }
    resources = {
        cpu = 250
        memory = 250
    }
    # storage = local.storage_config
    # volumes = [
    #     {
    #         container_directory = "/config"
    #         remote_directory = "config"
    #     },
    #     {
    #         container_directory = "/data"
    #         remote_directory = "data"
    #     }
    # ]
}
#endregion
