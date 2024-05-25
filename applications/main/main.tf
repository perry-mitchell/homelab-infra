locals {
  k3s_db_name = "k3s_master"
}

module "server_k3s_db" {
    source = "../../modules/debian-k3s-db"

    database_name = local.k3s_db_name
    database_password = var.k3s_database_password
    database_user = var.k3s_database_username

    mysql_root_password = var.k3s_database_root_password

    server_ip = var.k3s_database_server.ip
    server_password = var.k3s_database_server.password
    server_user = var.k3s_database_server.user
    work_directory = var.k3s_database_server.work_dir
}


module "server_k3s" {
    depends_on = [ module.server_k3s_db ]

    for_each = var.k3s_servers

    source = "../../modules/debian-k3s"

    cluster_token = var.k3s_cluster_token
    database_uri = module.server_k3s_db.connection_uri
    node_labels = each.value.labels
    server_ip = each.value.ip
    server_node = each.value.server
    server_password = each.value.password
    server_user = each.value.user
    work_directory = each.value.work_dir
}
