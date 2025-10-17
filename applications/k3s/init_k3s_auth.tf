module "k3s_auth" {
    source = "../../modules/k3s-local-kubeconfig"

    server_ip = local.initial_node.ip
    server_password = local.initial_node.password
    server_user = local.initial_node.user
    timestamp = "2025-10-17"
}

module "ingress" {
    source = "../../modules/k8s-ingress"

    depends_on = [ module.k3s_auth ]
}
