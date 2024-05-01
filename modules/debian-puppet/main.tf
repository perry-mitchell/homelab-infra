# locals {
#     puppet_variables_contents = join("\n", [for key, value in var.env : format("$%s", "${key} = '${value}'")])
# }

locals {
    puppet_bin = "/opt/puppetlabs/bin/puppet"
    puppet_deb_remote_path = "${var.work_directory}/puppet.deb"
    puppet_file_remote_path = "${var.work_directory}/provision.pp"
    # puppet_variables = format("class { 'variables': %s }\n\n", local.puppet_variables_contents)
    puppet_variables = join("\n", [for key, value in var.vars : format("$%s", "${key} = '${value}'")])
    puppet_variables_remote_path = "${var.work_directory}/variables.txt"
}

resource "null_resource" "provision_script" {
    triggers = {
        puppet_config_remote = local.puppet_file_remote_path,
        puppet_config_hash = filemd5(var.puppet_file)
    }

    provisioner "file" {
        source = var.puppet_file
        destination = local.puppet_file_remote_path
    }

    connection {
        host = var.server_ip
        type = "ssh"
        user = var.server_user
        password = var.server_password
        agent = false
    }
}

resource "null_resource" "puppet" {
    triggers = {
        puppet_remote_path = local.puppet_deb_remote_path
    }

    provisioner "remote-exec" {
        inline = [
            "apt-get update",
            "apt-get upgrade",
            "apt-get install wget -y",
            "wget https://apt.puppet.com/puppet7-release-focal.deb -O ${local.puppet_deb_remote_path}",
            "dpkg -i ${local.puppet_deb_remote_path}",
            "rm ${local.puppet_deb_remote_path}",
            "apt-get update",
            "apt-get install puppet-agent"
        ]
    }

    connection {
        host = var.server_ip
        type = "ssh"
        user = var.server_user
        password = var.server_password
        agent = false
    }
}

resource "null_resource" "provision" {
    depends_on = [ null_resource.provision_script, null_resource.puppet ]

    triggers = {
        puppet_config_hash = filemd5(var.puppet_file)
        puppet_variables = local.puppet_variables
    }

    provisioner "file" {
        content = local.puppet_variables
        destination = local.puppet_variables_remote_path
    }

    provisioner "remote-exec" {
        inline = [
            "cat ${local.puppet_variables_remote_path} ${local.puppet_file_remote_path} > ${var.work_directory}/target.pp",
            "${local.puppet_bin} module install puppetlabs-stdlib --version 4.9.1",
            "${local.puppet_bin} apply ${var.work_directory}/target.pp"
        ]
    }

    connection {
        host = var.server_ip
        type = "ssh"
        user = var.server_user
        password = var.server_password
        agent = false
    }
}
