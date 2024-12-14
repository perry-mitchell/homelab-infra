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
        b2 = {
           source = "Backblaze/b2"
           version = "0.9.0"
        }
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
    }
}
