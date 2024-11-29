resource "mysql_user" "target" {
    user = var.new_username
    host = var.new_host
    plaintext_password = var.new_password
}
