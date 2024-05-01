terraform {
    required_providers {
        azurerm = {
            source = "hashicorp/mysql"
        }
    }
}

resource "mysql_database" "target" {
    name = var.database
}
