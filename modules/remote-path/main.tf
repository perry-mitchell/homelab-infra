resource "null_resource" "folder" {
    triggers = {
        chown = var.server_chown
        directory = var.ensure_directory
    }

    provisioner "remote-exec" {
        inline = [
            "mkdir -p ${var.ensure_directory}",
            "chown -R ${var.server_chown} ${var.ensure_directory}"
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
