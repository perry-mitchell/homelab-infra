terraform {
  required_providers {
    cloudflare = {
      source = "opentofu/cloudflare"
    }
    kubernetes = {
      source = "opentofu/kubernetes"
    }
    namecheap = {
      source = "namecheap/namecheap"
    }
  }
}
