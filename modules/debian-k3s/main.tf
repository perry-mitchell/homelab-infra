module "k3s_provisioning" {
    source = "../debian-puppet"

    puppet_file = "${path.module}/provision.pp"
    server_ip = var.server_ip
    server_password = var.server_password
    server_user = var.server_user
    work_directory = var.work_directory
}

module "k3s_server" {
    source = "../debian-puppet"

    count = var.server_node ? 1 : 0

    puppet_file = "${path.module}/k3s-server.pp"
    server_ip = var.server_ip
    server_password = var.server_password
    server_user = var.server_user
    vars = {
        k3sConfig = yamlencode({
            "datastore-endpoint": "${var.database_uri}"
            "node-label": [
                for key, value in var.node_labels: "${key}=${value}"
            ]
            "token": "${var.cluster_token}"
            "write-kubeconfig-mode": "0644"
        })
    }
    work_directory = var.work_directory
}
