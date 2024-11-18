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

    required_providers {}
}
