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

module "nfs_storage_primary" {
    source = "../../modules/k8s-nfs-provisioner"

    nfs_export = var.nfs_storage_primary.export
    nfs_server = var.nfs_storage_primary.host
}

#region Remote Access
module "tailscale_subnet" {
    source = "../../modules/tailscale-subnet"

    additional_cidrs = var.network_cidrs
    auth_key = var.tailscale_container_auth
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
    dns_config = {
        cluster_fqdn = var.cluster_fqdn
        host_ip = local.primary_ingress_ip
        subdomain_name = "mariadb"
    }
    environment = {
        MARIADB_ROOT_PASSWORD = var.db_mariadb_root
        TZ = "Europe/Helsinki"
    }
    image = {
        tag = "latest"
        uri = "mariadb"
    }
    ingress_enabled = false
    mounts = {
        mysql = {
            container_path = "/var/lib/mysql"
            storage_request = "50Gi"
        }
    }
    name = local.mariadb_service_name
    namespace = kubernetes_namespace.datasources.metadata[0].name
    service_port = 3306
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
            storage_request = "5Gi"
        }
    }
    name = "smokeping"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    service_port = 80
}
#endregion

#region Business
resource "random_password" "kimai_database_user" {
    length = 32
    special = false
}
module "db_init_kimai" {
    source = "../../modules/mysql-init"

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
#endregion
