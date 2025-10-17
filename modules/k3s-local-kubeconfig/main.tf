locals {
  kubeconfig_remote_path = "/etc/rancher/k3s/k3s.yaml"
  kubeconfig_local_path  = "${path.module}/../../applications/k3s/kube.config"
}

resource "null_resource" "copy_kubeconfig" {
  triggers = {
    as_of       = var.timestamp
    local_path  = local.kubeconfig_local_path
    remote_path = local.kubeconfig_remote_path
  }

  provisioner "local-exec" {
    command = join(
      "\n",
      [
        "sshpass -p '${var.server_password}' scp -o StrictHostKeyChecking=no ${var.server_user}@${var.server_ip}:${local.kubeconfig_remote_path} ${local.kubeconfig_local_path}"
      ]
    )
  }
}
