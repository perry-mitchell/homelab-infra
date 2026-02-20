terraform {
  required_providers {
    kubernetes = {
      source = "opentofu/kubernetes"
    }
    helm = {
      source = "opentofu/helm"
    }
  }
}
