terraform {
  required_providers {
    helm = {
      source  = "opentofu/helm"
      version = ">= 2.16.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0"
    }
    kubernetes = {
      source  = "opentofu/kubernetes"
      version = ">= 2.33.0"
    }
  }
}
