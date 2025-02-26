locals {
  initial_node = one([
    for node in var.nodes: node
        if node.name == var.cluster_init_node && node.is_master == true
  ])
  other_master_nodes = {
    for node in var.nodes: node.name => node
        if node.name != var.cluster_init_node && node.is_master == true
  }
  worker_nodes = {
    for node in var.nodes: node.name => node
        if node.is_master == false
  }
  primary_ingress_ip = local.initial_node.ip
}

module "k3s_master_init" {
    source = "../../modules/k3s"

    cluster_init = true
    cluster_token = var.cluster_token
    fqdn = var.cluster_fqdn
    hostname = "${local.initial_node.name}.${var.cluster_fqdn}"
    is_master = true
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
    hostname = "${each.value.name}.${var.cluster_fqdn}"
    is_master = true
    main_server_ip = local.initial_node.ip
    node_name = each.value.name
    server_ip = each.value.ip
    server_password = each.value.password
    server_user = each.value.user
}

module "k3s_worker" {
    source = "../../modules/k3s"

    depends_on = [ module.k3s_master_init, module.k3s_master_join ]
    for_each = local.worker_nodes

    cluster_token = var.cluster_token
    hostname = "${each.value.name}.${var.cluster_fqdn}"
    is_master = false
    main_server_ip = local.initial_node.ip
    node_name = each.value.name
    server_ip = each.value.ip
    server_password = each.value.password
    server_user = each.value.user
}

module "k3s_node_labels" {
    source = "../../modules/k8s-node-meta"

    depends_on = [ module.k3s_master_init, module.k3s_master_join ]
    for_each = { for node in var.nodes : node.name => node }

    labels = coalesce(each.value.labels, {})
    node_name = each.value.name
}
