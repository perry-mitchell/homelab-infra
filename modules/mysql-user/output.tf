output "password" {
    value = var.new_password
}

output "username" {
    value = mysql_user.target.user
}
