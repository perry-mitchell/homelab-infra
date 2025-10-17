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
      source  = "Backblaze/b2"
      version = "0.9.0"
    }
    cloudflare = {
      source  = "opentofu/cloudflare"
      version = "4.48.0"
    }
    helm = {
      source  = "opentofu/helm"
      version = "2.16.1"
    }
    kubernetes = {
      source  = "opentofu/kubernetes"
      version = "2.33.0"
    }
    namecheap = {
      source  = "namecheap/namecheap"
      version = ">= 2.2.0"
    }
    pihole = {
      source  = "ryanwholey/pihole"
      version = "2.0.0-beta.1"
    }
  }
}
