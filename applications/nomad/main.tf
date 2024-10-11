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
    mount = local.storage_config.mount
    name = "alpha"
    server = local.storage_config.server
}
#endregion

#region Databases
module "db_mariadb" {
    source = "../../modules/nomad-service"

    depends_on = [ module.nomad_nfs ]
    datacenter = var.datacenter
    environment = {
        MARIADB_ROOT_PASSWORD = var.db_mariadb_root
        TZ = "Europe/Helsinki"
    }
    image = "mariadb:latest"
    name = "mariadb"
    ports = {
      "35002" = "3306"
    }
    resources = {
        cpu = 500
        memory = 1500
    }
    storage = local.storage_config
    volumes = {
        "mysql" = {
            container_directory = "/var/lib/mysql"
        }
    }
}
#endregion

#region Daemons
module "daemon_tailscale" {
    source = "../../modules/nomad-tailscale"

    depends_on = [ module.nomad_nfs ]
    datacenter = var.datacenter
    name = "tailscale"
    resources = {
        cpu = 150
        memory = 100
    }
    storage = local.storage_config
    tailscale_auth_key = var.tailscale_container_auth
    tailscale_hostname = "tailscale-nomad"
    tailscale_routes = "192.168.0.0/24,192.168.200.0/24,192.168.201.0/24"
}
#endregion

#region Apps
module "app_smokeping" {
    source = "../../modules/nomad-service"

    depends_on = [ module.nomad_nfs ]
    datacenter = var.datacenter
    environment = {
      TZ = "Europe/Helsinki"
    }
    image = "lscr.io/linuxserver/smokeping:latest"
    name = "smokeping"
    ports = {
        "35000" = "80"
    }
    resources = {
        cpu = 250
        memory = 250
    }
    mounts = [
        {
            directory = "/config"
            files = [
                {
                    contents = file("${path.module}/config/smokeping/Targets")
                    filename = "Targets"
                }
            ]
        }
    ]
    storage = local.storage_config
    volumes = {
        data = {
            container_directory = "/data"
        }
    }
}

module "app_minecraft_argon" {
    source = "../../modules/nomad-service"

    depends_on = [ module.nomad_nfs ]
    datacenter = var.datacenter
    environment = {
        ENABLE_ROLLING_LOGS = "true"
        EULA = "TRUE"
        GUI = "FALSE"
        JVM_XX_OPTS = "-XX:MaxRAMPercentage=80"
        MEMORY = ""
        TYPE = "SPIGOT"
        TZ = "Europe/Helsinki"
        # Minecraft server properties:
        DIFFICULTY = "easy"
        MAX_BUILD_HEIGHT = "512"
        MAX_WORLD_SIZE = "100000"
        MODE = "SURVIVAL"
        MOTD = "Welcome to Argon. Go forth and b̴̠́̏u̶͈̟̮͌͋͒̀̊͘͜i̵͖͌́l̴̗͊̃͘͜d̶͎̑̈́̍̐̀͝"
        PVP = "false"
        SERVER_NAME = "Argon"
        SEED = "34352807432"
        SNOOPER_ENABLED = "false"
        SPAWN_PROTECTION = "1"
        VIEW_DISTANCE = "10"
    }
    image = "itzg/minecraft-server:stable"
    name = "minecraft-argon"
    ports = {
        "25565" = "25565"
    }
    resources = {
      cpu = 1500
      memory = 8192
    }
    storage = local.storage_config
    volumes = {
        data = {
            container_directory = "/data"
        }
    }
}
#endregion
