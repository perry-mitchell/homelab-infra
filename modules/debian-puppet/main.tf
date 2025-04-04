locals {
    puppet_bin = "/opt/puppetlabs/bin/puppet"
    puppet_deb_remote_path = "${var.work_directory}/puppet.deb"
    puppet_file_remote_path = "${var.work_directory}/provision.pp"
    puppet_variables = join("\n", [for key, value in var.vars : format("$%s", "${key} = base64('decode', '${base64encode(value)}')")])
    puppet_variables_remote_path = "${var.work_directory}/variables.txt"
}

resource "null_resource" "work_dir" {
    triggers = {
        work_directory = var.work_directory,
        puppet_config_hash = filemd5(var.puppet_file)
    }

    provisioner "remote-exec" {
        inline = [
            "mkdir -p ${var.work_directory}"
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

resource "null_resource" "provision_script" {
    depends_on = [ null_resource.work_dir ]

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
    depends_on = [ null_resource.provision_script ]

    triggers = {
        puppet_remote_path = local.puppet_deb_remote_path
    }

    provisioner "remote-exec" {
        inline = [
            "apt-get update",
            "apt-get upgrade -y",
            "apt-get install wget -y",
            "wget https://apt.puppet.com/puppet7-release-focal.deb -O ${local.puppet_deb_remote_path}",
            "dpkg -i ${local.puppet_deb_remote_path}",
            "rm -f ${local.puppet_deb_remote_path}",
            "apt-get update",
            "apt-get install puppet-agent",
            "${local.puppet_bin} module install puppetlabs-stdlib --version 4.9.1 --force",
            "${local.puppet_bin} module install puppet-archive --version 7.1.0 --force"
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

resource "terraform_data" "provision" {
    depends_on = [ null_resource.work_dir, null_resource.provision_script, null_resource.puppet ]

    triggers_replace = {
        puppet_config_hash = filemd5(var.puppet_file)
        puppet_variables = local.puppet_variables
        "a" = 1
    }

    provisioner "file" {
        content = "${local.puppet_variables}\n"
        destination = local.puppet_variables_remote_path
    }

    provisioner "remote-exec" {
        inline = [
            "cat ${local.puppet_variables_remote_path} ${local.puppet_file_remote_path} > ${var.work_directory}/target.pp",
            "${local.puppet_bin} apply ${var.work_directory}/target.pp",
            "rm -f ${var.work_directory}/target.pp"
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
