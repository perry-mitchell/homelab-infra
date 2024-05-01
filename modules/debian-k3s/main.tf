module "k3s_provisioning" {
    source = "../debian-puppet"

    puppet_file = "${path.module}/provision.pp"
    server_ip = var.server_ip
    server_password = var.server_password
    server_user = var.server_user
    work_directory = var.work_directory
}

# locals {
#     puppet_bin = "/opt/puppetlabs/bin/puppet"
#     puppet_deb_remote_path = "${var.work_directory}/puppet.deb"
#     puppet_file_remote_path = "${var.work_directory}/provision.pp"
# }

# resource "null_resource" "provision_script" {
#     triggers = {
#         puppet_config_remote = local.puppet_file_remote_path,
#         puppet_config_hash = filemd5("${path.module}/provision.pp")
#     }

#     provisioner "file" {
#         source = "${path.module}/provision.pp"
#         destination = local.puppet_file_remote_path
#     }

#     connection {
#         host = var.server_ip
#         type = "ssh"
#         user = var.server_user
#         password = var.server_password
#         agent = false
#     }
# }

# resource "null_resource" "puppet" {
#     triggers = {
#         puppet_remote_path = local.puppet_deb_remote_path
#     }

#     provisioner "remote-exec" {
#         inline = [
#             "apt-get update",
#             "apt-get upgrade",
#             "apt-get install wget -y",
#             "wget https://apt.puppet.com/puppet7-release-focal.deb -O ${local.puppet_deb_remote_path}",
#             "dpkg -i ${local.puppet_deb_remote_path}",
#             "rm ${local.puppet_deb_remote_path}",
#             "apt-get update",
#             "apt-get install puppet-agent"
#         ]
#     }

#     connection {
#         host = var.server_ip
#         type = "ssh"
#         user = var.server_user
#         password = var.server_password
#         agent = false
#     }
# }

# resource "null_resource" "provision" {
#     depends_on = [ null_resource.provision_script, null_resource.puppet ]

#     triggers = {
#         puppet_config_hash = filemd5("${path.module}/provision.pp")
#         rand = 1
#     }

#     provisioner "remote-exec" {
#         inline = [
#             "${local.puppet_bin} apply ${local.puppet_file_remote_path}"
#         ]
#     }

#     connection {
#         host = var.server_ip
#         type = "ssh"
#         user = var.server_user
#         password = var.server_password
#         agent = false
#     }
# }
