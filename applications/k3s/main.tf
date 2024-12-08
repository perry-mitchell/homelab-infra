locals {
  initial_node = one([
    for node in var.nodes: node
        if node.name == var.cluster_init_node
  ])
  other_master_nodes = {
    for node in var.nodes: node.name => node
        if node.name != var.cluster_init_node && node.is_master == true
  }
  primary_ingress_ip = local.initial_node.ip
}

module "k3s_master_init" {
    source = "../../modules/k3s"

    cluster_init = true
    cluster_token = var.cluster_token
    fqdn = var.cluster_fqdn
    hostname = "${local.initial_node.name}.${var.cluster_fqdn}"
    main_server_ip = ""
    node_name = local.initial_node.name
    server_ip = local.initial_node.ip
    server_password = local.initial_node.password
    server_user = local.initial_node.user
}

module "k3s_master_join" {
    source = "../../modules/k3s"

    depends_on = [ module.k3s_master_init ]
    for_each = local.other_master_nodes

    cluster_init = false
    cluster_token = var.cluster_token
    fqdn = var.cluster_fqdn
    hostname = "${local.initial_node.name}.${var.cluster_fqdn}"
    main_server_ip = local.initial_node.ip
    node_name = each.value.name
    server_ip = each.value.ip
    server_password = each.value.password
    server_user = each.value.user
}

module "k3s_auth" {
    source = "../../modules/k3s-local-kubeconfig"

    server_ip = local.initial_node.ip
    server_password = local.initial_node.password
    server_user = local.initial_node.user
    timestamp = "2024-11-24"
}

module "ingress" {
    source = "../../modules/k8s-ingress"

    depends_on = [ module.k3s_auth ]
}

module "dashboard" {
    source = "../../modules/k8s-dashboard"

    depends_on = [ module.k3s_auth ]

    dns_config = {
        cluster_fqdn = var.cluster_fqdn
        host_ip = local.primary_ingress_ip
        subdomain_name = "k8s"
    }
}

module "nfs_storage" {
  source = "../../modules/k8s-nfs-provisioner"

  for_each = var.nfs_storage

  name = each.key
  nfs_export = each.value.export
  nfs_server = each.value.host
  path_pattern = each.value.path_pattern
}

#region Remote Access
module "tailscale_subnet" {
    source = "../../modules/tailscale-subnet"

    additional_cidrs = var.network_cidrs
    auth_key = var.tailscale_container_auth
    storage = "appdata"
}

# module "tailscale_subnet-2" {
#     source = "../../modules/tailscale-subnet-2"

#     additional_cidrs = var.network_cidrs
#     auth_key = var.tailscale_container_auth
#     storage = "appdata"
# }

module "tailscale" {
    source = "../../modules/tailscale"

    oauth = {
      client_id = var.tailscale_oauth.client_id
      client_secret = var.tailscale_oauth.client_secret
    }
}
#endregion

#region Datasources
resource "kubernetes_namespace" "datasources" {
    depends_on = [ module.k3s_auth ]

    metadata {
        name = "datasources"
    }
}

module "db_mariadb" {
    source = "../../modules/service"

    container_port = 3306
    # dns_config = {
    #     cluster_fqdn = var.cluster_fqdn
    #     host_ip = local.primary_ingress_ip
    #     subdomain_name = "mariadb"
    # }
    environment = {
        MARIADB_ROOT_PASSWORD = var.db_mariadb_root
        TZ = "Europe/Helsinki"
    }
    image = {
        tag = "latest"
        uri = "mariadb"
    }
    mounts = {
        mysql = {
            container_path = "/var/lib/mysql"
            storage = "appdata"
            storage_request = "50Gi"
        }
    }
    name = local.mariadb_service_name
    namespace = kubernetes_namespace.datasources.metadata[0].name
    service_port = 3306
    tailscale = {
      hostname = "mariadb"
      host_ip = local.primary_ingress_ip
      tailnet = var.tailscale_tailnet
    }
}

module "db_postgres" {
    source = "../../modules/service"

    container_port = 5432
    # dns_config = {
    #     cluster_fqdn = var.cluster_fqdn
    #     host_ip = local.primary_ingress_ip
    #     subdomain_name = "postgres"
    # }
    environment = {
        POSTGRES_PASSWORD = var.db_postgres_root
        POSTGRES_USER = "root"
        TZ = "Europe/Helsinki"
    }
    image = {
        tag = "13"
        uri = "postgres"
    }
    mounts = {
        data = {
            container_path = "/var/lib/postgresql/data"
            storage = "appdata"
            storage_request = "50Gi"
        }
    }
    name = local.postgres_service_name
    namespace = kubernetes_namespace.datasources.metadata[0].name
    service_port = 5432
    tailscale = {
      hostname = "postgres"
      host_ip = local.primary_ingress_ip
      tailnet = var.tailscale_tailnet
    }
}

module "db_postgres_pgvecto_rs" {
    source = "../../modules/service"

    container_port = 5432
    dns_config = {
        cluster_fqdn = var.cluster_fqdn
        host_ip = local.primary_ingress_ip
        subdomain_name = "postgres-pgvecto-rs"
    }
    environment = {
        POSTGRES_PASSWORD = var.db_postgres_pgvecto_rs_root
        POSTGRES_USER = "root"
        TZ = "Europe/Helsinki"
    }
    image = {
        tag = "pg14-v0.2.0"
        uri = "tensorchord/pgvecto-rs"
    }
    mounts = {
        data = {
            container_path = "/var/lib/postgresql/data"
            storage = "appdata"
            storage_request = "50Gi"
        }
    }
    name = local.postgres_pgvecto_rs_service_name
    namespace = kubernetes_namespace.datasources.metadata[0].name
    service_port = 5432
    tailscale = {
      hostname = "postgres-pgvecto-rs"
      host_ip = local.primary_ingress_ip
      tailnet = var.tailscale_tailnet
    }
}

module "db_redis" {
    source = "../../modules/service"

    container_port = 6379
    # dns_config = {
    #     cluster_fqdn = var.cluster_fqdn
    #     host_ip = local.primary_ingress_ip
    #     subdomain_name = "redis"
    # }
    environment = {
        ALLOW_EMPTY_PASSWORD = "no"
        REDIS_PASSWORD = var.db_redis_root
    }
    image = {
        tag = "latest"
        uri = "bitnami/redis"
    }
    mounts = {
        data = {
            container_path = "/bitnami/redis/data"
            storage = "appdata"
            storage_request = "10Gi"
        }
    }
    name = local.redis_service_name
    namespace = kubernetes_namespace.datasources.metadata[0].name
    service_port = 6379
    # tailscale = {
    #   hostname = "redis"
    #   tailnet = var.tailscale_tailnet
    # }
}
#endregion

#region Monitoring
resource "kubernetes_namespace" "monitoring" {
    depends_on = [ module.k3s_auth ]

    metadata {
        name = "monitoring"
    }
}

module "app_smokeping" {
    source = "../../modules/service"

    container_port = 80
    dns_config = {
        cluster_fqdn = var.cluster_fqdn
        host_ip = local.primary_ingress_ip
        subdomain_name = "smokeping"
    }
    files = {
        "/config/Targets" = file("${path.module}/config/smokeping/Targets")
    }
    image = {
        tag = "latest"
        uri = "lscr.io/linuxserver/smokeping"
    }
    mounts = {
        data = {
            container_path = "/data"
            storage = "appdata"
            storage_request = "5Gi"
        }
    }
    name = "smokeping"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    service_port = 80
    tailscale = {
        hostname = "smokeping"
        host_ip = local.primary_ingress_ip
        tailnet = var.tailscale_tailnet
    }
}
#endregion

#region Business
resource "kubernetes_namespace" "business" {
    depends_on = [ module.k3s_auth ]

    metadata {
        name = "business"
    }
}

resource "random_password" "kimai_database_user" {
    length = 32
    special = false
}
module "db_init_kimai" {
    source = "../../modules/mysql-init"

    depends_on = [ module.db_mariadb ]

    create_database = "kimai"
    create_user = {
        password = random_password.kimai_database_user.result
        username = "kimai"
    }
    db_host = local.mariadb_service_hostname
    db_password = var.db_mariadb_root
    db_username = "root"
    grant_users = {
        "kimai" = "kimai"
    }
    name = "kimai"
}
module "app_kimai" {
    source = "../../modules/service"

    depends_on = [ module.db_init_kimai ]

    container_port = 8001
    dns_config = {
        cluster_fqdn = var.cluster_fqdn
        host_ip = local.primary_ingress_ip
        subdomain_name = "kimai"
    }
    environment = {
        TZ = "Europe/Helsinki"
        ADMINMAIL = var.kimai_admin.email
        ADMINPASS = var.kimai_admin.password
        DATABASE_URL = "mysql://kimai:${random_password.kimai_database_user.result}@${local.mariadb_service_hostname}:3306/kimai?charset=utf8mb4"
    }
    image = {
        tag = "apache"
        uri = "kimai/kimai2"
    }
    mounts = {
        data = {
            container_path = "/opt/kimai/var/data"
            storage = "appdata"
            storage_request = "20Gi"
        }
    }
    name = "kimai"
    namespace = kubernetes_namespace.business.metadata[0].name
    service_port = 80
    tailscale = {
        hostname = "kimai"
        host_ip = local.primary_ingress_ip
        tailnet = var.tailscale_tailnet
    }
}
#endregion

#region Family
resource "kubernetes_namespace" "family" {
    depends_on = [ module.k3s_auth ]

    metadata {
        name = "family"
    }
}

resource "random_password" "immich_database_user" {
    length = 32
    special = false
}
module "db_init_immich" {
    source = "../../modules/postgres-init"

    depends_on = [ module.db_postgres_pgvecto_rs ]

    create_database = "immich"
    create_user = {
        password = random_password.immich_database_user.result
        username = "immich"
    }
    db_host = local.postgres_pgvecto_rs_service_hostname
    db_password = var.db_postgres_pgvecto_rs_root
    db_username = "root"
    extra_sql_lines = [
        "ALTER USER immich WITH SUPERUSER"
    ]
    name = "immich"
}

locals {
    immich_tag = "v1.122.1"
}

module "app_immich_ml" {
    source = "../../modules/service"

    depends_on = [ module.db_init_immich ]

    container_port = 3003
    # dns_config = {
    #     cluster_fqdn = var.cluster_fqdn
    #     host_ip = local.primary_ingress_ip
    #     subdomain_name = "immich-ml"
    # }
    environment = {
        TZ = "Europe/Helsinki"
    }
    image = {
        tag = local.immich_tag
        uri = "ghcr.io/immich-app/immich-machine-learning"
    }
    mounts = {
        "model-cache" = {
            container_path = "/cache"
            storage = "appdata"
            storage_request = "100Gi"
        }
    }
    name = "immich-ml"
    namespace = kubernetes_namespace.family.metadata[0].name
    service_port = 3003
}

module "app_immich" {
    source = "../../modules/service"

    depends_on = [ module.db_init_immich, module.app_immich_ml ]

    container_port = 2283
    dns_config = {
        cluster_fqdn = var.cluster_fqdn
        host_ip = local.primary_ingress_ip
        subdomain_name = "immich"
    }
    environment = {
        DB_DATABASE_NAME = "immich"
        DB_HOSTNAME = local.postgres_pgvecto_rs_service_hostname
        DB_PASSWORD = random_password.immich_database_user.result
        DB_PORT = "5432"
        DB_USERNAME = "immich"
        IMMICH_CONFIG_FILE = "/usr/src/app/immich.json"
        IMMICH_PORT = "2283"
        REDIS_DBINDEX = local.redis_db_reservations.immich
        REDIS_HOSTNAME = local.redis_service_hostname
        REDIS_PASSWORD = var.db_redis_root
        REDIS_PORT = "6379"
        TZ = "Europe/Helsinki"
    }
    files = {
        "/usr/src/app/immich.json" = file("${path.module}/config/immich/immich.json")
    }
    image = {
        tag = local.immich_tag
        uri = "ghcr.io/immich-app/immich-server"
    }
    ingress_upload_size = "2G"
    mounts = {
        "upload" = {
            container_path = "/usr/src/app/upload"
            storage = "photos"
            storage_request = "1500Gi"
        }
    }
    name = "immich"
    namespace = kubernetes_namespace.family.metadata[0].name
    service_port = 80
    tailscale = {
        hostname = "immich"
        host_ip = local.primary_ingress_ip
        tailnet = var.tailscale_tailnet
    }
}
#endregion
