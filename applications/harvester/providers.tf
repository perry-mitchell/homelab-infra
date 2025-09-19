provider "harvester" {
  kubeconfig = "./kube.config"
}

provider "helm" {
    kubernetes {
        config_path = "./kube.config"
        config_context = "local"
        insecure       = true
    }
}

provider "kubernetes" {
    config_path    = "./kube.config"
    config_context = "local"
    insecure       = true
}
