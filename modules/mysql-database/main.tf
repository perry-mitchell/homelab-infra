terraform {
    required_providers {
        azurerm = {
            source = "hashicorp/mysql"
        }
    }
}

resource "mysql_database" "target" {
    name = var.database

    default_character_set = "utf8mb4"
    default_collation = "utf8mb4_general_ci"
}

resource "mysql_grant" "target" {
    for_each = toset(var.attach_users)

    user       = each.value
    host       = "%"
    database   = mysql_database.target.name
    privileges = ["ALL"]
}
