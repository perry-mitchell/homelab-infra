locals {
  initial_node = one([
    for node in var.nodes: node
        if node.name == var.cluster_init_node
  ])
}

# module "cluster_db" {
#     source = "../../modules/debian-mariadb"

#     root_password = var.cluster_db_root_password
#     server_ip = var.cluster_db_node.ip
#     server_password = var.cluster_db_node.password
#     server_user = var.cluster_db_node.user
# }

module "k3s_master_init" {
    source = "../../modules/k3s"

    cluster_init = true
    cluster_token = var.cluster_token
    node_name = local.initial_node.name
    server_ip = local.initial_node.ip
    server_password = local.initial_node.password
    server_user = local.initial_node.user
}
