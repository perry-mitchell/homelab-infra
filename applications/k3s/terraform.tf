terraform {
    encryption {
        key_provider "pbkdf2" "primary" {
            passphrase = var.state_encryption_passphrase
        }

        method "aes_gcm" "primary" {
            keys = key_provider.pbkdf2.primary
        }

        state {
            method = method.aes_gcm.primary
        }

        plan {
            method = method.aes_gcm.primary
        }
    }

    required_providers {
        helm = {
            source = "opentofu/helm"
            version = "2.16.1"
        }
        kubernetes = {
            source = "opentofu/kubernetes"
            version = "2.33.0"
        }
        pihole = {
            source = "ryanwholey/pihole"
            version = "0.2.0"
        }
        mysql = {
            source = "petoju/mysql"
            version = "3.0.67"
        }
    }
}
