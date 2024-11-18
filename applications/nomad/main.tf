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

#region DNS
# module "nomad_master_dns" {
#     source = "../../modules/debian-dns-consul"

#     depends_on = [ module.nomad_master ]

#     dns_server = var.nomad_master.ip
#     server_ip = var.nomad_master.ip
#     server_password = var.nomad_master.password
#     server_user = var.nomad_master.user
#     work_directory = "${var.nomad_master.work_dir}/consul-dns"
# }

module "nomad_worker_dns" {
    source = "../../modules/debian-dns-consul"

    for_each = {
      for index, worker in var.nomad_workers: worker.name => worker
    }

    depends_on = [ module.nomad_worker ]

    dns_server = var.nomad_master.ip
    server_ip = each.value.ip
    server_password = each.value.password
    server_user = each.value.user
    work_directory = "${each.value.work_dir}/consul-dns"
}
#endregion

locals {
    storage_config = {
        mount = var.storage_backends.alpha.mount
        name = "alpha"
        server = var.storage_backends.alpha.server
        server_chown = "nobody:users"
        server_password = var.storage_backends.alpha.server_password
        server_user = var.storage_backends.alpha.server_user
    }
}

#region Storage
# module "nomad_nfs" {
#     source = "../../modules/nomad-nfs"

#     depends_on = [module.nomad_master, module.nomad_worker]

#     datacenter = var.datacenter
#     mount = local.storage_config.mount
#     name = "alpha"
#     server = local.storage_config.server
# }
# module "nomad_nfs" {
#     source = "../../modules/nomad-nfs"

#     depends_on = [module.nomad_master, module.nomad_worker]

#     datacenter = var.datacenter
#     mount = local.storage_config.mount
#     name = "alpha"
#     server = local.storage_config.server
# }
#endregion

#region Databases
# module "db_mariadb" {
#     source = "../../modules/nomad-service"

#     depends_on = [ module.nomad_nfs ]
#     datacenter = var.datacenter
#     environment = {
#         MARIADB_ROOT_PASSWORD = var.db_mariadb_root
#         TZ = "Europe/Helsinki"
#     }
#     image = "mariadb:latest"
#     name = "mariadb"
#     ports = {
#       "35002" = "3306"
#     }
#     resources = {
#         cpu = 500
#         memory = 1500
#     }
#     storage = local.storage_config
#     volumes = [
#         {
#             container_directory = "/var/lib/mysql"
#             mount_name = "mysql"
#         }
#     ]
# }
#endregion

#region Apps
# module "app_smokeping" {
#     source = "../../modules/nomad-service"

#     depends_on = [ module.nomad_nfs ]
#     datacenter = var.datacenter
#     environment = {
#       TZ = "Europe/Helsinki"
#     }
#     image = "lscr.io/linuxserver/smokeping:latest"
#     name = "smokeping"
#     ports = {
#         "35000" = "80"
#     }
#     resources = {
#         cpu = 250
#         memory = 250
#     }
#     mounts = [
#         {
#             directory = "/config"
#             files = [
#                 {
#                     contents = file("${path.module}/config/smokeping/Targets")
#                     filename = "Targets"
#                 }
#             ]
#         }
#     ]
#     storage = local.storage_config
#     volumes = [
#         {
#             container_directory = "/data"
#             mount_name = "data"
#         }
#     ]
# }

# module "app_tailscale" {
#     source = "../../modules/nomad-service"

#     depends_on = [ module.nomad_nfs ]
#     datacenter = var.datacenter
#     docker_cap_add = ["NET_ADMIN", "SYS_MODULE"]
#     docker_hostname = "tailscale-nomad"
#     docker_network_mode = "bridge"
#     docker_privileged = true
#     docker_volumes = ["/dev/net/tun:/dev/net/tun"]
#     environment = {
#         TS_AUTHKEY    = "${var.tailscale_container_auth}"
#         TS_EXTRA_ARGS = "--advertise-tags=tag:container --accept-routes --advertise-exit-node"
#         TS_HOSTNAME   = "tailscale-nomad"
#         TS_ROUTES     = "192.168.0.0/24,192.168.200.0/24,192.168.201.0/24"
#         TS_STATE_DIR  = "/var/lib/tailscale"
#     }
#     image = "tailscale/tailscale:latest"
#     name = "tailscale"
#     resources = {
#         cpu = 150
#         memory = 100
#     }
#     storage = local.storage_config
#     volumes = [
#         {
#             container_directory = "/var/lib/tailscale"
#             mount_name = "var"
#         }
#     ]
# }

# module "app_minecraft_argon" {
#     source = "../../modules/nomad-service"

#     depends_on = [ module.nomad_nfs ]
#     datacenter = var.datacenter
#     environment = {
#         ENABLE_ROLLING_LOGS = "true"
#         EULA = "TRUE"
#         GUI = "FALSE"
#         JVM_XX_OPTS = "-XX:MaxRAMPercentage=80"
#         MEMORY = ""
#         REPLACE_ENV_VARIABLES = "TRUE"
#         TYPE = "SPIGOT"
#         TZ = "Europe/Helsinki"
#         # Minecraft server properties:
#         DIFFICULTY = "easy"
#         MAX_BUILD_HEIGHT = "512"
#         MAX_WORLD_SIZE = "100000"
#         MODE = "SURVIVAL"
#         MOTD = "Welcome to Argon. Go forth and b̴̠́̏u̶͈̟̮͌͋͒̀̊͘͜i̵͖͌́l̴̗͊̃͘͜d̶͎̑̈́̍̐̀͝"
#         ONLINE_MODE = "FALSE"
#         PVP = "false"
#         SERVER_NAME = "Argon"
#         SEED = "34352807432"
#         SNOOPER_ENABLED = "false"
#         SPAWN_PROTECTION = "1"
#         VIEW_DISTANCE = "10"
#     }
#     image = "itzg/minecraft-server:stable"
#     name = "minecraft-argon"
#     ports = {
#         "25566" = "25565"
#     }
#     resources = {
#       cpu = 1500
#       memory = 8192
#     }
#     storage = local.storage_config
#     volumes = [
#         {
#             container_directory = "/data"
#             mount_name = "data"
#         }
#     ]
# }

# module "app_minecraft_router" {
#     source = "../../modules/nomad-service"

#     depends_on = [ module.app_minecraft_argon ]
#     datacenter = var.datacenter
#     environment = {
#         JVM_XX_OPTS = "-XX:MaxRAMPercentage=90"
#         MEMORY = ""
#         REPLACE_ENV_VARIABLES = "TRUE"
#         TYPE = "BUNGEECORD"
#     }
#     image = "itzg/mc-proxy:stable"
#     name = "minecraft-router"
#     mounts = [
#         {
#             directory = "/config"
#             files = [
#                 {
#                     contents = file("${path.module}/config/minecraft/bungeecord.yml")
#                     filename = "config.yml"
#                 }
#             ]
#         }
#     ]
#     ports = {
#         "25565" = "25577"
#     }
#     resources = {
#         cpu = 350
#         memory = 768
#     }
#     storage = local.storage_config
#     volumes = [
#         {
#             container_directory = "/server"
#             mount_name = "data"
#         },
#         {
#             container_directory = "/plugins"
#             mount_name = "plugins"
#         }
#     ]
# }
#endregion
