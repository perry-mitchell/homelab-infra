output "connection_uri" {
    value = "mysql://${module.k3s_db_user.username}:${module.k3s_db_user.password}@${var.server_ip}:3306/${module.k3s_db.database}"
}
