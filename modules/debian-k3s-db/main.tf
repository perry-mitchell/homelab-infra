provider "mysql" {
    endpoint = "${var.server_ip}:3306"
    username = "root"
    password = var.mysql_root_password
}


module "k3s_db_provisioning" {
    source = "../debian-puppet"

    puppet_file = "${path.module}/provision.pp"
    server_ip = var.server_ip
    server_password = var.server_password
    server_user = var.server_user
    work_directory = var.work_directory
    vars = {
        mysqlRootPassword = var.mysql_root_password
    }
}

module "k3s_db_user" {
    source = "../mysql-user"

    depends_on = [ module.k3s_db_provisioning ]

    providers = {
        mysql = mysql
    }

    new_host = "%"
    new_password = var.database_password
    new_username = var.database_user
}

# module "k3s_db_user" {
#     source = "../mysql-database"

#     depends_on = [ module.k3s_db_user ]

#     providers = {
#         mysql = mysql
#     }

#     attach_users = [var.database_user]
#     database = var.database_name
# }
