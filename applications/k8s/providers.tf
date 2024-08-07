terraform {
    required_providers {
        mysql = {
            source = "petoju/mysql"
            version = "3.0.53"
        }
    }

    backend "pg" {
        schema_name = "app_main"
    }
}
