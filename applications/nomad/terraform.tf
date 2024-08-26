terraform {
    encryption {
        key_provider "pbkdf2" "primary" {
            passphrase = var.state_encryption_passphrase
        }

        method "unencrypted" "migrate" {}

        method "aes_gcm" "primary" {
            keys = key_provider.pbkdf2.primary
        }

        state {
            method = method.aes_gcm.primary

            fallback {
                method = method.unencrypted.migrate
            }
        }

        plan {
            method = method.aes_gcm.primary

            fallback {
                method = method.unencrypted.migrate
            }
        }
    }

    required_providers {
        # digitalocean = {
        #     source  = "digitalocean/digitalocean"
        #     version = "~> 2.40"
        # }
    }
}
